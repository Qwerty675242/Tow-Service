angular.module('beamng.apps')
.directive('towServiceSettings', [function() {
  return {
    templateUrl: '/ui/modules/apps/TowService/app.html',
    replace: true,
    restrict: 'E',
    link: function(scope, element, attrs) {

      scope.startMission = function() {
        if (window.bngApi && window.bngApi.engineLua) {
          window.bngApi.engineLua('towServiceTrigger.startMission()');
        } else if (typeof bngApi !== 'undefined' && bngApi.engineLua) {
          bngApi.engineLua('towServiceTrigger.startMission()');
        }
      };

      scope.cancelMission = function() {
        if (window.bngApi && window.bngApi.engineLua) {
          window.bngApi.engineLua('towServiceTrigger.cancelMission()');
        } else if (typeof bngApi !== 'undefined' && bngApi.engineLua) {
          bngApi.engineLua('towServiceTrigger.cancelMission()');
        }
      };

    }
  };
}]);