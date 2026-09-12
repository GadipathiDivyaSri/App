// WrindhaOS Interactive Tools & Modals Runtime v4.0 (Navy Blue Dark Theme & Clean State)
(function() {
  function getIsDark(ctx) { return false; }

  // =========================================================================
  // 1. FOCUS TIMER & STOPWATCH MODAL (Navy Blue Dark Palette)
  // =========================================================================
  window._openFocusTimerModal = function(ctx) {
    try {
      var isDark = getIsDark(ctx);
      var totalSec = 25 * 60;
      var remainingSec = totalSec;
      var isRunning = false;
      var timerId = null;
      var isStopwatch = false;
      var swElapsed = 0;
      var swRunning = false;
      var swTimerId = null;
      var swLaps = [];

      function formatTime(sec) {
        var m = Math.floor(sec / 60);
        var s = sec % 60;
        return (m < 10 ? '0' : '') + m + ':' + (s < 10 ? '0' : '') + s;
      }

      function formatStopwatch(ms) {
        var m = Math.floor(ms / 6000);
        var s = Math.floor((ms % 6000) / 100);
        var cs = ms % 100;
        return (m < 10 ? '0' : '') + m + ':' + (s < 10 ? '0' : '') + s + '.' + (cs < 10 ? '0' : '') + cs;
      }

      var existingOverlay = document.getElementById('wrindha_focus_modal');
      if (existingOverlay) existingOverlay.remove();

      var overlay = document.createElement('div');
      overlay.id = 'wrindha_focus_modal';
      overlay.style.position = 'fixed';
      overlay.style.top = '0';
      overlay.style.left = '0';
      overlay.style.width = '100vw';
      overlay.style.height = '100vh';
      overlay.style.backgroundColor = 'rgba(10, 17, 40, 0.82)';
      overlay.style.backdropFilter = 'blur(12px)';
      overlay.style.zIndex = '999999';
      overlay.style.display = 'flex';
      overlay.style.justifyContent = 'center';
      overlay.style.alignItems = 'center';
      overlay.style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';

      overlay.innerHTML = `
        <div style="background: ${isDark ? '#0A1128' : '#FFF9F0'}; color: ${isDark ? '#F1F5F9' : '#1E293B'}; width: 90%; max-width: 460px; border-radius: 28px; padding: 28px; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.45); border: 1px solid ${isDark ? '#1E2F5E' : '#E2E8F0'}; position: relative; max-height: 90vh; overflow-y: auto;">
          <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
            <div style="display: flex; align-items: center; gap: 10px;">
              <div style="background: #0D5CE5; color: white; width: 38px; height: 38px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 20px;">⏱️</div>
              <div>
                <h2 style="margin: 0; font-size: 18px; font-weight: 800;">Focus Tools</h2>
                <p style="margin: 0; font-size: 12px; color: ${isDark ? '#94A3B8' : '#64748B'};">Deep Work Pomodoro & Stopwatch</p>
              </div>
            </div>
            <button id="close_focus_modal" style="background: transparent; border: none; font-size: 24px; cursor: pointer; color: #94A3B8;">&times;</button>
          </div>

          <!-- Mode Selector -->
          <div style="display: flex; background: ${isDark ? '#101B3B' : '#E2E8F0'}; border-radius: 14px; padding: 4px; margin-bottom: 24px; border: 1px solid ${isDark ? '#1E2F5E' : 'transparent'};">
            <button id="mode_pomodoro" style="flex: 1; padding: 10px; border: none; border-radius: 10px; font-weight: 700; cursor: pointer; background: #0D5CE5; color: white;">Pomodoro (25m)</button>
            <button id="mode_stopwatch" style="flex: 1; padding: 10px; border: none; border-radius: 10px; font-weight: 700; cursor: pointer; background: transparent; color: #94A3B8;">Stopwatch</button>
          </div>

          <!-- Pomodoro View -->
          <div id="pomodoro_section" style="text-align: center;">
            <div style="width: 190px; height: 190px; border-radius: 50%; border: 6px solid #0D5CE5; margin: 0 auto 24px; display: flex; flex-direction: column; justify-content: center; align-items: center; background: ${isDark ? '#101B3B' : '#FFFFFF'}; box-shadow: ${isDark ? '0 8px 24px rgba(13,92,229,0.18)' : 'none'};">
              <span id="pomo_timer_display" style="font-size: 42px; font-weight: 900; letter-spacing: -1px; font-variant-numeric: tabular-nums;">25:00</span>
              <span id="pomo_status" style="font-size: 12px; font-weight: 700; color: #38BDF8; letter-spacing: 1px; text-transform: uppercase;">DEEP FOCUS</span>
            </div>
            <div style="display: flex; gap: 12px; justify-content: center;">
              <button id="btn_pomo_start" style="background: #0D5CE5; color: white; border: none; padding: 12px 28px; border-radius: 14px; font-size: 15px; font-weight: 800; cursor: pointer;">Start</button>
              <button id="btn_pomo_reset" style="background: ${isDark ? '#162347' : '#E2E8F0'}; color: ${isDark ? '#F1F5F9' : '#1E293B'}; border: 1px solid ${isDark ? '#1E2F5E' : 'transparent'}; padding: 12px 20px; border-radius: 14px; font-size: 15px; font-weight: 700; cursor: pointer;">Reset</button>
            </div>
            <div style="display: flex; gap: 8px; justify-content: center; margin-top: 18px;">
              <button class="pomo_preset" data-min="15" style="background: transparent; border: 1px solid ${isDark ? '#1E2F5E' : '#CBD5E1'}; color: inherit; border-radius: 8px; padding: 4px 10px; font-size: 12px; cursor: pointer;">15m</button>
              <button class="pomo_preset" data-min="25" style="background: #0D5CE5; color: white; border: 1px solid #0D5CE5; border-radius: 8px; padding: 4px 10px; font-size: 12px; cursor: pointer;">25m</button>
              <button class="pomo_preset" data-min="45" style="background: transparent; border: 1px solid ${isDark ? '#1E2F5E' : '#CBD5E1'}; color: inherit; border-radius: 8px; padding: 4px 10px; font-size: 12px; cursor: pointer;">45m</button>
              <button class="pomo_preset" data-min="60" style="background: transparent; border: 1px solid ${isDark ? '#1E2F5E' : '#CBD5E1'}; color: inherit; border-radius: 8px; padding: 4px 10px; font-size: 12px; cursor: pointer;">60m</button>
            </div>
          </div>

          <!-- Stopwatch View -->
          <div id="stopwatch_section" style="display: none; text-align: center;">
            <div style="margin: 20px 0 24px;">
              <span id="sw_timer_display" style="font-size: 46px; font-weight: 900; letter-spacing: -1px; font-variant-numeric: tabular-nums;">00:00.00</span>
            </div>
            <div style="display: flex; gap: 12px; justify-content: center; margin-bottom: 20px;">
              <button id="btn_sw_start" style="background: #0D5CE5; color: white; border: none; padding: 12px 28px; border-radius: 14px; font-size: 15px; font-weight: 800; cursor: pointer;">Start</button>
              <button id="btn_sw_lap" style="background: #10B981; color: white; border: none; padding: 12px 20px; border-radius: 14px; font-size: 15px; font-weight: 700; cursor: pointer;">Lap</button>
              <button id="btn_sw_reset" style="background: ${isDark ? '#162347' : '#E2E8F0'}; color: ${isDark ? '#F1F5F9' : '#1E293B'}; border: 1px solid ${isDark ? '#1E2F5E' : 'transparent'}; padding: 12px 20px; border-radius: 14px; font-size: 15px; font-weight: 700; cursor: pointer;">Reset</button>
            </div>
            <div id="sw_laps_container" style="max-height: 140px; overflow-y: auto; text-align: left; background: ${isDark ? '#101B3B' : '#F1F5F9'}; border: 1px solid ${isDark ? '#1E2F5E' : 'transparent'}; border-radius: 12px; padding: 10px;">
              <div style="font-size: 12px; color: #94A3B8; text-align: center;">No laps recorded yet</div>
            </div>
          </div>
        </div>
      `;

      document.body.appendChild(overlay);

      var closeBtn = overlay.querySelector('#close_focus_modal');
      if (closeBtn) {
        closeBtn.onclick = function() {
          clearInterval(timerId);
          clearInterval(swTimerId);
          overlay.remove();
        };
      }

      var modePomo = overlay.querySelector('#mode_pomodoro');
      var modeSw = overlay.querySelector('#mode_stopwatch');
      var pomoSec = overlay.querySelector('#pomodoro_section');
      var swSec = overlay.querySelector('#stopwatch_section');

      if (modePomo && modeSw && pomoSec && swSec) {
        modePomo.onclick = function() {
          isStopwatch = false;
          modePomo.style.background = '#0D5CE5';
          modePomo.style.color = '#FFF';
          modeSw.style.background = 'transparent';
          modeSw.style.color = '#94A3B8';
          pomoSec.style.display = 'block';
          swSec.style.display = 'none';
        };

        modeSw.onclick = function() {
          isStopwatch = true;
          modeSw.style.background = '#0D5CE5';
          modeSw.style.color = '#FFF';
          modePomo.style.background = 'transparent';
          modePomo.style.color = '#94A3B8';
          swSec.style.display = 'block';
          pomoSec.style.display = 'none';
        };
      }

      var btnPomoStart = overlay.querySelector('#btn_pomo_start');
      var btnPomoReset = overlay.querySelector('#btn_pomo_reset');
      var pomoDisplay = overlay.querySelector('#pomo_timer_display');

      if (btnPomoStart && btnPomoReset && pomoDisplay) {
        btnPomoStart.onclick = function() {
          if (!isRunning) {
            isRunning = true;
            btnPomoStart.innerText = 'Pause';
            btnPomoStart.style.background = '#EF4444';
            timerId = setInterval(function() {
              if (remainingSec > 0) {
                remainingSec--;
                pomoDisplay.innerText = formatTime(remainingSec);
              } else {
                clearInterval(timerId);
                isRunning = false;
                btnPomoStart.innerText = 'Start';
                btnPomoStart.style.background = '#0D5CE5';
                alert('🎉 Focus Session Completed! Take a well-deserved break.');
              }
            }, 1000);
          } else {
            clearInterval(timerId);
            isRunning = false;
            btnPomoStart.innerText = 'Resume';
            btnPomoStart.style.background = '#0D5CE5';
          }
        };

        btnPomoReset.onclick = function() {
          clearInterval(timerId);
          isRunning = false;
          remainingSec = totalSec;
          pomoDisplay.innerText = formatTime(remainingSec);
          btnPomoStart.innerText = 'Start';
          btnPomoStart.style.background = '#0D5CE5';
        };
      }

      overlay.querySelectorAll('.pomo_preset').forEach(function(btn) {
        btn.onclick = function() {
          overlay.querySelectorAll('.pomo_preset').forEach(function(b) {
            b.style.background = 'transparent';
            b.style.color = 'inherit';
          });
          btn.style.background = '#0D5CE5';
          btn.style.color = 'white';
          var m = parseInt(btn.getAttribute('data-min'));
          totalSec = m * 60;
          remainingSec = totalSec;
          if (pomoDisplay) pomoDisplay.innerText = formatTime(remainingSec);
          if (isRunning) {
            clearInterval(timerId);
            isRunning = false;
            if (btnPomoStart) {
              btnPomoStart.innerText = 'Start';
              btnPomoStart.style.background = '#0D5CE5';
            }
          }
        };
      });

      var btnSwStart = overlay.querySelector('#btn_sw_start');
      var btnSwLap = overlay.querySelector('#btn_sw_lap');
      var btnSwReset = overlay.querySelector('#btn_sw_reset');
      var swDisplay = overlay.querySelector('#sw_timer_display');
      var swLapsContainer = overlay.querySelector('#sw_laps_container');

      if (btnSwStart && btnSwLap && btnSwReset && swDisplay && swLapsContainer) {
        btnSwStart.onclick = function() {
          if (!swRunning) {
            swRunning = true;
            btnSwStart.innerText = 'Pause';
            btnSwStart.style.background = '#EF4444';
            var startTime = Date.now() - swElapsed;
            swTimerId = setInterval(function() {
              swElapsed = Date.now() - startTime;
              swDisplay.innerText = formatStopwatch(Math.floor(swElapsed / 10));
            }, 10);
          } else {
            clearInterval(swTimerId);
            swRunning = false;
            btnSwStart.innerText = 'Resume';
            btnSwStart.style.background = '#0D5CE5';
          }
        };

        btnSwLap.onclick = function() {
          if (swRunning) {
            var lapTime = formatStopwatch(Math.floor(swElapsed / 10));
            swLaps.unshift({ num: swLaps.length + 1, time: lapTime });
            swLapsContainer.innerHTML = swLaps.map(function(l) {
              return '<div style="display:flex; justify-content:space-between; padding:4px 8px; border-bottom:1px solid ' + (isDark ? '#1E2F5E' : '#CBD5E1') + '; font-size:12px;"><span>Lap ' + l.num + '</span><strong>' + l.time + '</strong></div>';
            }).join('');
          }
        };

        btnSwReset.onclick = function() {
          clearInterval(swTimerId);
          swRunning = false;
          swElapsed = 0;
          swLaps = [];
          swDisplay.innerText = '00:00.00';
          btnSwStart.innerText = 'Start';
          btnSwStart.style.background = '#0D5CE5';
          swLapsContainer.innerHTML = '<div style="font-size: 12px; color: #94A3B8; text-align: center;">No laps recorded yet</div>';
        };
      }
    } catch(err) {
      console.error('[FOCUS MODAL ERROR]:', err);
    }
  };

  // =========================================================================
  // 2. GOALS MANAGEMENT MODAL (Clean State: 0 Predefined Goals & Navy Blue)
  // =========================================================================
  window._openGoalsModal = window._openGoalPyramidModal = function(ctx) {
    try {
      var isDark = getIsDark(ctx);
      var existingOverlay = document.getElementById('wrindha_goal_modal');
      if (existingOverlay) existingOverlay.remove();

      var storageKey = 'wrindha_goals_data_v2';
      // Completely clean empty default state (No predefined mock goals)
      var defaultGoals = {
        short: [],
        medium: [],
        long: []
      };

      try {
        var str = localStorage.getItem(storageKey);
        if (str) {
          var parsed = JSON.parse(str);
          if (parsed && typeof parsed === 'object') {
            defaultGoals = parsed;
          }
        }
      } catch(e) {}

      // Ensure tier arrays exist
      ['short', 'medium', 'long'].forEach(function(t) {
        if (!Array.isArray(defaultGoals[t])) defaultGoals[t] = [];
      });

      function saveGoals() {
        try {
          localStorage.setItem(storageKey, JSON.stringify(defaultGoals));
        } catch(e) {}
      }

      var overlay = document.createElement('div');
      overlay.id = 'wrindha_goal_modal';
      overlay.style.position = 'fixed';
      overlay.style.top = '0';
      overlay.style.left = '0';
      overlay.style.width = '100vw';
      overlay.style.height = '100vh';
      overlay.style.backgroundColor = 'rgba(10, 17, 40, 0.82)';
      overlay.style.backdropFilter = 'blur(12px)';
      overlay.style.zIndex = '999999';
      overlay.style.display = 'flex';
      overlay.style.justifyContent = 'center';
      overlay.style.alignItems = 'center';
      overlay.style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';

      document.body.appendChild(overlay);

      var activeTab = 'short';

      function renderModal() {
        var goals = defaultGoals[activeTab] || [];
        var completedCount = goals.filter(function(g) { return g.isDone; }).length;
        var totalCount = goals.length;
        var pct = totalCount === 0 ? 0 : Math.round((completedCount / totalCount) * 100);

        var tabName = activeTab === 'short' ? 'Short-Term' : activeTab === 'medium' ? 'Medium-Term' : 'Long-Term';
        var tabIcon = activeTab === 'short' ? '⚡' : activeTab === 'medium' ? '📅' : '🏔️';

        overlay.innerHTML = `
          <div style="background: ${isDark ? '#0A1128' : '#FFF9F0'}; color: ${isDark ? '#F1F5F9' : '#1E293B'}; width: 90%; max-width: 520px; border-radius: 28px; padding: 28px; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.45); border: 1px solid ${isDark ? '#1E2F5E' : '#E2E8F0'}; max-height: 90vh; overflow-y: auto;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
              <div style="display: flex; align-items: center; gap: 10px;">
                <div style="background: #E87552; color: white; width: 40px; height: 40px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 22px;">🎯</div>
                <div>
                  <h2 style="margin: 0; font-size: 19px; font-weight: 800;">Goals Management</h2>
                  <p style="margin: 0; font-size: 12px; color: ${isDark ? '#94A3B8' : '#64748B'};">Short-Term, Medium-Term & Long-Term Targets</p>
                </div>
              </div>
              <button id="close_goal_modal" style="background: transparent; border: none; font-size: 24px; cursor: pointer; color: #94A3B8;">&times;</button>
            </div>

            <!-- Tier Tabs -->
            <div style="display: flex; background: ${isDark ? '#101B3B' : '#E2E8F0'}; border-radius: 14px; padding: 4px; margin-bottom: 16px; border: 1px solid ${isDark ? '#1E2F5E' : 'transparent'};">
              <button id="tab_short" style="flex: 1; padding: 10px; border: none; border-radius: 10px; font-weight: 700; font-size: 13px; cursor: pointer; background: ${activeTab === 'short' ? '#E87552' : 'transparent'}; color: ${activeTab === 'short' ? '#FFF' : '#94A3B8'};">⚡ Short-Term</button>
              <button id="tab_medium" style="flex: 1; padding: 10px; border: none; border-radius: 10px; font-weight: 700; font-size: 13px; cursor: pointer; background: ${activeTab === 'medium' ? '#E87552' : 'transparent'}; color: ${activeTab === 'medium' ? '#FFF' : '#94A3B8'};">📅 Medium-Term</button>
              <button id="tab_long" style="flex: 1; padding: 10px; border: none; border-radius: 10px; font-weight: 700; font-size: 13px; cursor: pointer; background: ${activeTab === 'long' ? '#E87552' : 'transparent'}; color: ${activeTab === 'long' ? '#FFF' : '#94A3B8'};">🏔️ Long-Term</button>
            </div>

            <!-- Progress Summary Card -->
            <div style="background: ${isDark ? '#101B3B' : '#FFF'}; border: 1px solid ${isDark ? '#1E2F5E' : '#E2E8F0'}; border-radius: 16px; padding: 14px 16px; margin-bottom: 18px;">
              <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                <span style="font-size: 12px; font-weight: 800; color: #E87552;">${tabIcon} ${tabName.toUpperCase()} PROGRESS</span>
                <span style="font-size: 14px; font-weight: 900; color: #E87552;">${completedCount} / ${totalCount} Done (${pct}%)</span>
              </div>
              <div style="background: ${isDark ? '#1E2F5E' : '#E2E8F0'}; height: 8px; border-radius: 4px; overflow: hidden;">
                <div style="background: #E87552; height: 100%; width: ${pct}%; border-radius: 4px; transition: width 0.3s ease;"></div>
              </div>
            </div>

            <!-- Add Goal Input -->
            <div style="display: flex; gap: 8px; margin-bottom: 18px;">
              <input id="input_goal_title" type="text" placeholder="Add ${tabName.toLowerCase()} goal (e.g. Finish Chapter 1)..." style="flex: 1; padding: 12px 14px; border-radius: 12px; border: 1px solid ${isDark ? '#1E2F5E' : '#CBD5E1'}; background: ${isDark ? '#101B3B' : '#FFF'}; color: inherit; font-size: 13px; outline: none;" />
              <button id="btn_add_goal" style="background: #E87552; color: white; border: none; padding: 12px 18px; border-radius: 12px; font-weight: 800; font-size: 13px; cursor: pointer;">+ Add Goal</button>
            </div>

            <!-- Goals List with Interactive Checkboxes -->
            <div id="goals_list_container">
              ${goals.length === 0 ? '<div style="text-align:center; padding:32px 16px; color:#94A3B8; font-size:13px; background:' + (isDark ? '#101B3B' : '#F8FAFC') + '; border:1px dashed ' + (isDark ? '#1E2F5E' : '#CBD5E1') + '; border-radius:16px;">No goals added yet in this tier.<br/><span style="font-size:11px; opacity:0.8;">Type your goal above and tap (+ Add Goal) to start!</span></div>' : ''}
              ${goals.map(function(g, idx) {
                return `
                  <div style="display: flex; align-items: center; justify-content: space-between; background: ${isDark ? '#101B3B' : '#FFFFFF'}; padding: 12px 16px; border-radius: 14px; margin-bottom: 10px; border: 1px solid ${isDark ? '#1E2F5E' : '#E2E8F0'};">
                    <label style="display: flex; align-items: center; gap: 12px; cursor: pointer; flex: 1;">
                      <input type="checkbox" class="goal_checkbox" data-idx="${idx}" ${g.isDone ? 'checked' : ''} style="width: 20px; height: 20px; cursor: pointer; accent-color: #E87552;" />
                      <div>
                        <div style="font-weight: 700; font-size: 14px; text-decoration: ${g.isDone ? 'line-through' : 'none'}; color: ${g.isDone ? '#94A3B8' : 'inherit'};">${g.title}</div>
                        <div style="font-size: 11px; color: #94A3B8;">Target: ${g.targetDate || 'Vision Target'}</div>
                      </div>
                    </label>
                    <button class="goal_delete" data-idx="${idx}" style="background: transparent; border: none; color: #EF4444; font-size: 18px; cursor: pointer; padding: 4px 8px;">&times;</button>
                  </div>
                `;
              }).join('')}
            </div>
          </div>
        `;

        var closeBtn = overlay.querySelector('#close_goal_modal');
        if (closeBtn) closeBtn.onclick = function() { overlay.remove(); };

        var tShort = overlay.querySelector('#tab_short');
        if (tShort) tShort.onclick = function() { activeTab = 'short'; renderModal(); };

        var tMed = overlay.querySelector('#tab_medium');
        if (tMed) tMed.onclick = function() { activeTab = 'medium'; renderModal(); };

        var tLong = overlay.querySelector('#tab_long');
        if (tLong) tLong.onclick = function() { activeTab = 'long'; renderModal(); };

        function submitNewGoal() {
          var input = overlay.querySelector('#input_goal_title');
          var val = input ? input.value.trim() : '';
          if (val) {
            defaultGoals[activeTab].push({
              id: 'g_' + Date.now(),
              title: val,
              targetDate: activeTab === 'short' ? 'This Week' : activeTab === 'medium' ? 'This Month' : 'Vision Target',
              isDone: false
            });
            saveGoals();
            renderModal();
          }
        }

        var addBtn = overlay.querySelector('#btn_add_goal');
        if (addBtn) addBtn.onclick = submitNewGoal;

        var goalInp = overlay.querySelector('#input_goal_title');
        if (goalInp) {
          goalInp.onkeydown = function(e) {
            if (e.key === 'Enter') submitNewGoal();
          };
        }

        overlay.querySelectorAll('.goal_checkbox').forEach(function(cb) {
          cb.onchange = function() {
            var idx = parseInt(cb.getAttribute('data-idx'));
            if (defaultGoals[activeTab][idx]) {
              defaultGoals[activeTab][idx].isDone = cb.checked;
              saveGoals();
              renderModal();
            }
          };
        });

        overlay.querySelectorAll('.goal_delete').forEach(function(btn) {
          btn.onclick = function(e) {
            e.stopPropagation();
            var idx = parseInt(btn.getAttribute('data-idx'));
            defaultGoals[activeTab].splice(idx, 1);
            saveGoals();
            renderModal();
          };
        });
      }

      renderModal();
    } catch(err) {
      console.error('[GOALS MODAL ERROR]:', err);
    }
  };

  // =========================================================================
  // 3. SUBJECT CURRICULUM UNITS & TOPICS (Clean State: 0 Predefined Units)
  // =========================================================================
  window._openSubjectUnitsModal = function(ctx, subject) {
    try {
      var isDark = getIsDark(ctx);
      var existingOverlay = document.getElementById('wrindha_subject_modal');
      if (existingOverlay) existingOverlay.remove();

      // Resolve clicked subject name
      var subjName = '';
      if (typeof subject === 'string' && subject.trim()) {
        subjName = subject.trim();
      } else if (subject && typeof subject === 'object') {
        subjName = subject.b || subject.a || subject.name || subject.title || '';
      }

      if (!subjName || typeof subjName !== 'string') subjName = 'Academic Subject';

      var storageKey = 'wrindha_units_v2_' + subjName.toLowerCase().replace(/[^a-z0-9]/g, '_');

      function loadUnitsForSubject() {
        var savedUnits = null;
        try {
          var str = localStorage.getItem(storageKey);
          if (str) savedUnits = JSON.parse(str);
        } catch(e) {}

        // Completely clean empty default state (No predefined mock units or topics)
        if (!savedUnits || !Array.isArray(savedUnits)) {
          savedUnits = [];
        }
        return savedUnits;
      }

      var unitsList = loadUnitsForSubject();

      function saveSubjectUnits() {
        try {
          localStorage.setItem(storageKey, JSON.stringify(unitsList));
        } catch(e) {}
      }

      function calculateStats() {
        var totalTopics = 0;
        var completedTopics = 0;
        var totalUnits = unitsList.length;
        var completedUnits = 0;

        unitsList.forEach(function(u) {
          var uTopics = u.topics || [];
          var uCompleted = 0;
          uTopics.forEach(function(t) {
            totalTopics++;
            if (t.isDone) {
              completedTopics++;
              uCompleted++;
            }
          });
          if (uTopics.length > 0 && uCompleted === uTopics.length) {
            completedUnits++;
          }
        });

        var pct = totalTopics === 0 ? 0 : Math.round((completedTopics / totalTopics) * 100);
        return {
          pct: pct,
          totalTopics: totalTopics,
          completedTopics: completedTopics,
          totalUnits: totalUnits,
          completedUnits: completedUnits
        };
      }

      var overlay = document.createElement('div');
      overlay.id = 'wrindha_subject_modal';
      overlay.style.position = 'fixed';
      overlay.style.top = '0';
      overlay.style.left = '0';
      overlay.style.width = '100vw';
      overlay.style.height = '100vh';
      overlay.style.backgroundColor = 'rgba(10, 17, 40, 0.82)';
      overlay.style.backdropFilter = 'blur(12px)';
      overlay.style.zIndex = '999999';
      overlay.style.display = 'flex';
      overlay.style.justifyContent = 'center';
      overlay.style.alignItems = 'center';
      overlay.style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';

      document.body.appendChild(overlay);

      function renderSubjectModal() {
        var stats = calculateStats();

        overlay.innerHTML = `
          <div style="background: ${isDark ? '#0A1128' : '#FFF9F0'}; color: ${isDark ? '#F1F5F9' : '#1E293B'}; width: 90%; max-width: 560px; border-radius: 28px; padding: 26px; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.45); border: 1px solid ${isDark ? '#1E2F5E' : '#E2E8F0'}; max-height: 90vh; overflow-y: auto;">
            
            <!-- Modal Header -->
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
              <div style="display: flex; align-items: center; gap: 12px;">
                <div style="background: #0D5CE5; color: white; width: 42px; height: 42px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 22px;">📚</div>
                <div>
                  <h2 style="margin: 0; font-size: 19px; font-weight: 800;">${subjName}</h2>
                  <p style="margin: 0; font-size: 12px; color: ${isDark ? '#94A3B8' : '#64748B'};">Curriculum Units & Topics Progress</p>
                </div>
              </div>
              <button id="close_subject_modal" style="background: transparent; border: none; font-size: 26px; cursor: pointer; color: #94A3B8;">&times;</button>
            </div>

            <!-- Overall Mastery Progress Bar & Stats -->
            <div style="background: ${isDark ? '#101B3B' : '#EEF2FF'}; padding: 16px 20px; border-radius: 20px; margin-bottom: 20px; border: 1px solid ${isDark ? '#1E2F5E' : '#C7D2FE'};">
              <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                <span style="font-size: 12px; font-weight: 800; letter-spacing: 1px; color: #38BDF8; text-transform: uppercase;">📊 SUBJECT MASTERY PROGRESS</span>
                <span style="font-size: 22px; font-weight: 900; color: #38BDF8;">${stats.pct}%</span>
              </div>
              <div style="background: ${isDark ? '#1E2F5E' : '#E0E7FF'}; height: 10px; border-radius: 5px; overflow: hidden; margin-bottom: 10px;">
                <div style="background: linear-gradient(90deg, #0D5CE5, #10B981); height: 100%; width: ${stats.pct}%; border-radius: 5px; transition: width 0.3s ease;"></div>
              </div>
              <div style="display: flex; justify-content: space-between; font-size: 12px; color: ${isDark ? '#94A3B8' : '#64748B'}; font-weight: 600;">
                <span>${stats.completedTopics} / ${stats.totalTopics} Topics Completed</span>
                <span>${stats.completedUnits} / ${stats.totalUnits} Units Completed</span>
              </div>
            </div>

            <!-- Add Unit Form -->
            <div style="display: flex; gap: 8px; margin-bottom: 20px;">
              <input id="input_unit_title" type="text" placeholder="Add new unit (e.g. Unit 1: Fundamentals)..." style="flex: 1; padding: 12px 14px; border-radius: 12px; border: 1px solid ${isDark ? '#1E2F5E' : '#CBD5E1'}; background: ${isDark ? '#101B3B' : '#FFF'}; color: inherit; font-size: 13px; outline: none;" />
              <button id="btn_add_unit" style="background: #0D5CE5; color: white; border: none; padding: 12px 18px; border-radius: 12px; font-weight: 800; font-size: 13px; cursor: pointer;">+ Add Unit</button>
            </div>

            <!-- Units & Topics List -->
            <div id="units_container">
              ${unitsList.length === 0 ? '<div style="text-align:center; padding:32px 16px; color:#94A3B8; font-size:13px; background:' + (isDark ? '#101B3B' : '#F8FAFC') + '; border:1px dashed ' + (isDark ? '#1E2F5E' : '#CBD5E1') + '; border-radius:16px;">No units added yet for ' + subjName + '.<br/><span style="font-size:11px; opacity:0.8;">Use the input above and tap (+ Add Unit) to start!</span></div>' : ''}
              ${unitsList.map(function(u, uIdx) {
                var uTopics = u.topics || [];
                var uDoneCount = uTopics.filter(function(t) { return t.isDone; }).length;
                var uTotalCount = uTopics.length;
                var uAllDone = uTotalCount > 0 && uDoneCount === uTotalCount;
                var uPct = uTotalCount === 0 ? 0 : Math.round((uDoneCount / uTotalCount) * 100);

                return `
                  <div style="background: ${isDark ? '#101B3B' : '#FFFFFF'}; border-radius: 18px; padding: 16px; margin-bottom: 14px; border: 1px solid ${isDark ? '#1E2F5E' : '#E2E8F0'}; box-shadow: 0 2px 6px rgba(0,0,0,0.03);">
                    
                    <!-- Unit Header with Checkbox -->
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
                      <label style="display: flex; align-items: center; gap: 10px; cursor: pointer; flex: 1;">
                        <input type="checkbox" class="unit_cb" data-uidx="${uIdx}" ${uAllDone ? 'checked' : ''} style="width: 20px; height: 20px; accent-color: #10B981; cursor: pointer;" />
                        <div>
                          <h4 style="margin: 0; font-size: 15px; font-weight: 800; text-decoration: ${uAllDone ? 'line-through' : 'none'}; color: ${uAllDone ? '#94A3B8' : 'inherit'};">${u.title}</h4>
                          <div style="font-size: 11px; font-weight: 700; color: ${uAllDone ? '#10B981' : (isDark ? '#38BDF8' : '#64748B')};">${uDoneCount}/${uTotalCount} Topics (${uPct}% Complete)</div>
                        </div>
                      </label>
                      <div style="display: flex; gap: 6px; align-items: center;">
                        <button class="btn_add_topic_to_unit" data-uidx="${uIdx}" style="background: ${isDark ? '#1E2F5E' : '#EEF2FF'}; color: ${isDark ? '#38BDF8' : '#0D5CE5'}; border: 1px solid ${isDark ? '#2E478C' : '#C7D2FE'}; border-radius: 8px; padding: 5px 10px; font-size: 11px; font-weight: 700; cursor: pointer;">+ Topic</button>
                        <button class="btn_delete_unit" data-uidx="${uIdx}" style="background: transparent; border: none; color: #EF4444; font-size: 18px; cursor: pointer; padding: 0 4px;">&times;</button>
                      </div>
                    </div>

                    <!-- Inline Topic Creator -->
                    <div id="topic_creator_${uIdx}" style="display: none; gap: 6px; margin-bottom: 12px;">
                      <input id="input_topic_${uIdx}" type="text" placeholder="Topic name (e.g. Overview & Scope)..." style="flex: 1; padding: 8px 12px; font-size: 12px; border-radius: 8px; border: 1px solid ${isDark ? '#1E2F5E' : '#CBD5E1'}; background: ${isDark ? '#0A1128' : '#FFF'}; color: inherit;" />
                      <button class="btn_confirm_topic" data-uidx="${uIdx}" style="background: #0D5CE5; color: white; border: none; padding: 8px 14px; border-radius: 8px; font-size: 12px; font-weight: 700; cursor: pointer;">Save Topic</button>
                    </div>

                    <!-- Topics List with Individual Checkboxes -->
                    <div style="display: flex; flex-direction: column; gap: 8px;">
                      ${uTopics.length === 0 ? '<div style="font-size:12px; color:#94A3B8; padding:4px 0;">No topics in this unit yet. Click (+ Topic) to add one!</div>' : uTopics.map(function(t, tIdx) {
                        return `
                          <div style="display: flex; align-items: center; justify-content: space-between; padding: 8px 10px; border-radius: 10px; background: ${isDark ? '#0A1128' : '#F8FAFC'}; border: 1px solid ${isDark ? '#1E2F5E' : '#F1F5F9'};">
                            <label style="display: flex; align-items: center; gap: 10px; cursor: pointer; flex: 1;">
                              <input type="checkbox" class="topic_cb" data-uidx="${uIdx}" data-tidx="${tIdx}" ${t.isDone ? 'checked' : ''} style="width: 17px; height: 17px; accent-color: #0D5CE5; cursor: pointer;" />
                              <span style="font-size: 13px; font-weight: 600; text-decoration: ${t.isDone ? 'line-through' : 'none'}; color: ${t.isDone ? '#94A3B8' : 'inherit'};">${t.title}</span>
                            </label>
                            <button class="btn_delete_topic" data-uidx="${uIdx}" data-tidx="${tIdx}" style="background: transparent; border: none; color: #EF4444; font-size: 16px; cursor: pointer; padding: 2px 6px;">&times;</button>
                          </div>
                        `;
                      }).join('')}
                    </div>
                  </div>
                `;
              }).join('')}
            </div>
          </div>
        `;

        var closeBtn = overlay.querySelector('#close_subject_modal');
        if (closeBtn) closeBtn.onclick = function() { overlay.remove(); };

        function submitNewUnit() {
          var input = overlay.querySelector('#input_unit_title');
          var val = input ? input.value.trim() : '';
          if (val) {
            unitsList.push({
              title: val,
              topics: []
            });
            saveSubjectUnits();
            renderSubjectModal();
          }
        }

        var addUnitBtn = overlay.querySelector('#btn_add_unit');
        if (addUnitBtn) addUnitBtn.onclick = submitNewUnit;

        var unitInp = overlay.querySelector('#input_unit_title');
        if (unitInp) {
          unitInp.onkeydown = function(e) {
            if (e.key === 'Enter') submitNewUnit();
          };
        }

        // Show/hide inline topic creator
        overlay.querySelectorAll('.btn_add_topic_to_unit').forEach(function(btn) {
          btn.onclick = function() {
            var uIdx = btn.getAttribute('data-uidx');
            var creator = overlay.querySelector('#topic_creator_' + uIdx);
            if (creator) {
              creator.style.display = creator.style.display === 'none' ? 'flex' : 'none';
              var inp = overlay.querySelector('#input_topic_' + uIdx);
              if (inp) {
                inp.focus();
                inp.onkeydown = function(e) {
                  if (e.key === 'Enter') {
                    var val = inp.value.trim();
                    if (val) {
                      unitsList[parseInt(uIdx)].topics = unitsList[parseInt(uIdx)].topics || [];
                      unitsList[parseInt(uIdx)].topics.push({ title: val, isDone: false });
                      saveSubjectUnits();
                      renderSubjectModal();
                    }
                  }
                };
              }
            }
          };
        });

        // Save new topic
        overlay.querySelectorAll('.btn_confirm_topic').forEach(function(btn) {
          btn.onclick = function() {
            var uIdx = parseInt(btn.getAttribute('data-uidx'));
            var inp = overlay.querySelector('#input_topic_' + uIdx);
            var val = inp ? inp.value.trim() : '';
            if (val) {
              unitsList[uIdx].topics = unitsList[uIdx].topics || [];
              unitsList[uIdx].topics.push({ title: val, isDone: false });
              saveSubjectUnits();
              renderSubjectModal();
            }
          };
        });

        // Delete Topic
        overlay.querySelectorAll('.btn_delete_topic').forEach(function(btn) {
          btn.onclick = function(e) {
            e.stopPropagation();
            var uIdx = parseInt(btn.getAttribute('data-uidx'));
            var tIdx = parseInt(btn.getAttribute('data-tidx'));
            unitsList[uIdx].topics.splice(tIdx, 1);
            saveSubjectUnits();
            renderSubjectModal();
          };
        });

        // Delete Unit
        overlay.querySelectorAll('.btn_delete_unit').forEach(function(btn) {
          btn.onclick = function(e) {
            e.stopPropagation();
            var uIdx = parseInt(btn.getAttribute('data-uidx'));
            unitsList.splice(uIdx, 1);
            saveSubjectUnits();
            renderSubjectModal();
          };
        });

        // Toggle Individual Topic Checkbox
        overlay.querySelectorAll('.topic_cb').forEach(function(cb) {
          cb.onchange = function() {
            var uIdx = parseInt(cb.getAttribute('data-uidx'));
            var tIdx = parseInt(cb.getAttribute('data-tidx'));
            unitsList[uIdx].topics[tIdx].isDone = cb.checked;
            saveSubjectUnits();
            renderSubjectModal();
          };
        });

        // Toggle Entire Unit Checkbox
        overlay.querySelectorAll('.unit_cb').forEach(function(cb) {
          cb.onchange = function() {
            var uIdx = parseInt(cb.getAttribute('data-uidx'));
            var targetState = cb.checked;
            (unitsList[uIdx].topics || []).forEach(function(t) {
              t.isDone = targetState;
            });
            saveSubjectUnits();
            renderSubjectModal();
          };
        });
      }

      renderSubjectModal();
    } catch(err) {
      console.error('[SUBJECT UNITS MODAL ERROR]:', err);
    }
  };
})();

window._performLogout = window.logout = function() {
  try {
    localStorage.clear();
    sessionStorage.clear();
  } catch(e){}
  if (typeof window !== 'undefined' && window.location) {
    window.location.reload();
  }
};
