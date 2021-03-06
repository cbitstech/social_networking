# frozen_string_literal: true
require "spec_helper"

module SocialNetworking
  RSpec.describe LikesController, type: :controller do
    routes { Engine.routes }

    let(:participant) do
      instance_double(
        Participant,
        display_name: "Robin",
        id: 1,
        is_admin: false
      )
    end
    let(:like) do
      instance_double(
        Like,
        created_at: Time.zone.now,
        id: "foo",
        participant_id: participant.id,
        item_id: 5,
        item_type: "SocialNetworking::Comment",
        participant: participant
      )
    end

    def recipient(attributes = {})
      instance_double(
        Participant, {
          contact_preference: nil
        }.merge(attributes)
      )
    end

    describe "POST create" do
      before do
        allow(controller)
          .to receive(:current_participant) { participant }
      end

      describe "when shared item is a 'Comment'" do
        before do
          allow(Like).to receive(:new) { like }
        end

        context "the record saves" do
          before do
            allow(like).to receive(:save) { true }
            allow(SocialNetworking::Comment)
              .to receive_message_chain("find.participant_id")
          end

          it "returns a json record" do
            allow(Participant).to receive(:find) { recipient }

            post :create

            assert_response 200

            expect(json["id"]).to eq("foo")
            expect(json["participantDisplayName"]).to eq("Robin")
            expect(json["participantId"]).to eq(participant.id)
          end

          describe "recipient prefers to be contacted via email" do
            let(:recipient_with_eamil) do
              recipient(contact_preference: "email")
            end

            before do
              allow(controller).to receive(:t) { "SunnySide" }
              allow(Participant)
                .to receive(:find) { recipient_with_eamil }
              allow(Notification)
                .to receive_message_chain("new.notify")
            end

            it "should notify via email with link and application name" do
              expect(Notification)
                .to receive(:new)
                .with(
                  current_participant: participant,
                  mailer: Mailer,
                  recipient: recipient_with_eamil,
                  message_body: %r{/social_networking/profile_page},
                  subject: /SunnySide/
                )

              post :create
            end
          end
        end

        context "the record doesn't save" do
          let(:errors) { double("errors", full_messages: ["baz"]) }

          it "returns an error message" do
            allow(like)
              .to receive_messages(save: false, errors: errors)

            post :create

            assert_response 400
            expect(json["error"]).to eq("baz")
          end
        end
      end

      describe "when shared item is a 'SharedItem'" do
        let(:shareable_item) do
          instance_double(
            Like,
            created_at: Time.zone.now,
            id: "bar",
            item_id: 1,
            item_type: "SocialNetworking::SharedItem",
            participant_id: participant.id,
            participant: participant
          )
        end

        before do
          allow(Like).to receive(:new) { shareable_item }
          expect(shareable_item).to receive(:save) { true }
          expect(SharedItem)
            .to receive_message_chain("find.item_type.constantize")
            .and_return(Like)
          expect(shareable_item)
            .to receive_message_chain("item.item_id")
          expect(Like)
            .to receive_message_chain("find.participant_id")
          expect(Participant).to receive(:find) { recipient }
        end

        describe "when the record saves" do
          it "has a successful request" do
            post :create

            assert_response 200
          end
        end
      end

      describe "when authorization token has expired" do
        before do
          allow(Like)
            .to receive(:new)
            .and_raise ActionController::InvalidAuthenticityToken

          post :create
        end

        it_behaves_like "an untrusted action"
      end
    end
  end
end
