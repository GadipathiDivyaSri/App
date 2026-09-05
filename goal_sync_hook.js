// Universal WrindhaOS Goals & Career Roadmap Real-time Database Sync Hook
(function() {
  function getAuthHeader() {
    var token = localStorage.getItem('flutter.wrindha_auth_token') || 
                localStorage.getItem('wrindha_auth_token') || 
                sessionStorage.getItem('wrindha_auth_token') ||
                localStorage.getItem('flutter.wrindha_secure_jwt_token') ||
                localStorage.getItem('wrindha_secure_jwt_token');
    if (token && token.startsWith('"') && token.endsWith('"')) {
      token = token.slice(1, -1);
    }
    return token ? { 'Authorization': 'Bearer ' + token } : {};
  }

  window.wrindhaSyncGoal = function(goal) {
    if (!goal || !goal.title) return;
    var headers = Object.assign({ 'Content-Type': 'application/json' }, getAuthHeader());
    fetch('/api/goals', {
      method: 'POST',
      headers: headers,
      body: JSON.stringify(goal)
    }).then(function(r) { return r.json(); }).then(function(d) {
      console.log('[Supabase Cloud Goal Sync Success]:', d.id || d);
    }).catch(function(err) {
      console.warn('[Goal Sync Notice]:', err);
    });
  };

  window.wrindhaDeleteGoal = function(goalId) {
    if (!goalId) return;
    var headers = Object.assign({ 'Content-Type': 'application/json' }, getAuthHeader());
    fetch('/api/goals/' + encodeURIComponent(goalId), {
      method: 'DELETE',
      headers: headers
    }).catch(function(err) {
      console.warn('[Goal Delete Notice]:', err);
    });
  };

  // Real-time localStorage hook for goals and career roadmaps
  var origSetItem = localStorage.setItem;
  localStorage.setItem = function(key, value) {
    origSetItem.apply(this, arguments);
    if (key.indexOf('saved_goals') !== -1 || key.indexOf('saved_career') !== -1) {
      try {
        var rawVal = value;
        if (typeof rawVal === 'string' && rawVal.startsWith('"') && rawVal.endsWith('"')) {
          try { rawVal = JSON.parse(rawVal); } catch(e){}
        }
        var items = typeof rawVal === 'string' ? JSON.parse(rawVal) : rawVal;
        if (Array.isArray(items)) {
          items.forEach(function(item) {
            window.wrindhaSyncGoal(item);
          });
        }
      } catch (_) {}
    }
  };
})();
