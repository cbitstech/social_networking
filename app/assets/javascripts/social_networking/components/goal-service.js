;(function() {
  'use strict';

  function Goals($resource) {
    var GoalResource = $resource('/social_networking/goals/:id',
      { id: '@id' });

    function Goal() {}

    // Retrieve all Goals from the server.
    Goal.getAll = function() {
      return GoalResource.query().$promise;
    };

    // Persist a Goal to the server.
    Goal.create = function(attributes) {
      var goal = new GoalResource({
        description: attributes.description
      });

      return goal.$save();
    };

    return Goal;
  }

  angular.module('socialNetworking.services')
    .service('Goals', ['$resource', Goals]);
})();