describe('ProfileCtrl', function() {
  var controller;
  
  beforeEach(function() {
    module('ngResource');
    module('socialNetworking.services');
    module('socialNetworking.profile.controllers');
  });

  beforeEach(inject(function($controller) {
    controller = $controller('ProfileCtrl');
  }));

  it('should set the username', function() {
    expect(controller.participant.username).toBe('Billy');
  });

  it('should set the last login', function() {
    expect(controller.lastLogin).toBe('2014-08-12T16:55:29Z');
  });
});
