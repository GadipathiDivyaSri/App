// WrindhaOS Interactive Tools & Modals Runtime
(function() {
  function getIsDark(ctx) {
    try {
      if (ctx && typeof A !== 'undefined' && A.r && typeof B !== 'undefined' && B.F) {
        return A.r(ctx).ax.a === B.F;
      }
    } catch(e) {}
    try {
      return (document.body.style.backgroundColor === 'rgb(30, 31, 43)' || window._isDarkMode === true);
    } catch(e) {
      return false;
    }
  }

  // --- FOCUS TIMER & STOPWATCH MODAL ---
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
      overlay.style.backgroundColor = 'rgba(15, 23, 42, 0.75)';
      overlay.style.backdropFilter = 'blur(10px)';
      overlay.style.zIndex = '999999';
      overlay.style.display = 'flex';
      overlay.style.justifyContent = 'center';
      overlay.style.alignItems = 'center';
      overlay.style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';

      overlay.innerHTML = `
        <div style="background: ${isDark ? '#1E1F2B' : '#FFF9F0'}; color: ${isDark ? '#FFF' : '#1E293B'}; width: 90%; max-width: 460px; border-radius: 28px; padding: 28px; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.35); border: 1px solid ${isDark ? '#2D2F3F' : '#E2E8F0'}; position: relative; max-height: 90vh; overflow-y: auto;">
          <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
            <div style="display: flex; align-items: center; gap: 10px;">
              <div style="background: #0D5CE5; color: white; width: 38px; height: 38px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 20px;">⏱️</div>
              <div>
                <h2 style="margin: 0; font-size: 18px; font-weight: 800;">Focus Tools</h2>
                <p style="margin: 0; font-size: 12px; color: #64748B;">Deep Work & Stopwatch</p>
              </div>
            </div>
            <button id="close_focus_modal" style="background: transparent; border: none; font-size: 24px; cursor: pointer; color: #94A3B8;">&times;</button>
          </div>

          <!-- Mode Selector -->
          <div style="display: flex; background: ${isDark ? '#14151F' : '#E2E8F0'}; border-radius: 14px; padding: 4px; margin-bottom: 24px;">
            <button id="mode_pomodoro" style="flex: 1; padding: 10px; border: none; border-radius: 10px; font-weight: 700; cursor: pointer; background: #0D5CE5; color: white;">Pomodoro (25m)</button>
            <button id="mode_stopwatch" style="flex: 1; padding: 10px; border: none; border-radius: 10px; font-weight: 700; cursor: pointer; background: transparent; color: #64748B;">Stopwatch</button>
          </div>

          <!-- Pomodoro View -->
          <div id="pomodoro_section" style="text-align: center;">
            <div style="width: 190px; height: 190px; border-radius: 50%; border: 6px solid #0D5CE5; margin: 0 auto 24px; display: flex; flex-direction: column; justify-content: center; align-items: center; background: ${isDark ? '#14151F' : '#FFFFFF'};">
              <span id="pomo_timer_display" style="font-size: 42px; font-weight: 900; letter-spacing: -1px; font-variant-numeric: tabular-nums;">25:00</span>
              <span id="pomo_status" style="font-size: 12px; font-weight: 700; color: #0D5CE5; letter-spacing: 1px; text-transform: uppercase;">DEEP FOCUS</span>
            </div>
            <div style="display: flex; gap: 12px; justify-content: center;">
              <button id="btn_pomo_start" style="background: #0D5CE5; color: white; border: none; padding: 12px 28px; border-radius: 14px; font-size: 15px; font-weight: 800; cursor: pointer;">Start</button>
              <button id="btn_pomo_reset" style="background: ${isDark ? '#2D2F3F' : '#E2E8F0'}; color: ${isDark ? '#FFF' : '#1E293B'}; border: none; padding: 12px 20px; border-radius: 14px; font-size: 15px; font-weight: 700; cursor: pointer;">Reset</button>
            </div>
            <div style="display: flex; gap: 8px; justify-content: center; margin-top: 18px;">
              <button class="pomo_preset" data-min="15" style="background: transparent; border: 1px solid #CBD5E1; border-radius: 8px; padding: 4px 10px; font-size: 12px; cursor: pointer;">15m</button>
              <button class="pomo_preset" data-min="25" style="background: #0D5CE5; color: white; border: 1px solid #0D5CE5; border-radius: 8px; padding: 4px 10px; font-size: 12px; cursor: pointer;">25m</button>
              <button class="pomo_preset" data-min="45" style="background: transparent; border: 1px solid #CBD5E1; border-radius: 8px; padding: 4px 10px; font-size: 12px; cursor: pointer;">45m</button>
              <button class="pomo_preset" data-min="60" style="background: transparent; border: 1px solid #CBD5E1; border-radius: 8px; padding: 4px 10px; font-size: 12px; cursor: pointer;">60m</button>
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
              <button id="btn_sw_reset" style="background: ${isDark ? '#2D2F3F' : '#E2E8F0'}; color: ${isDark ? '#FFF' : '#1E293B'}; border: none; padding: 12px 20px; border-radius: 14px; font-size: 15px; font-weight: 700; cursor: pointer;">Reset</button>
            </div>
            <div id="sw_laps_container" style="max-height: 140px; overflow-y: auto; text-align: left; background: ${isDark ? '#14151F' : '#F1F5F9'}; border-radius: 12px; padding: 10px;">
              <div style="font-size: 12px; color: #94A3B8; text-align: center;">No laps recorded yet</div>
            </div>
          </div>
        </div>
      `;

      document.body.appendChild(overlay);

      document.getElementById('close_focus_modal').onclick = function() {
        clearInterval(timerId);
        clearInterval(swTimerId);
        overlay.remove();
      };

      var modePomo = document.getElementById('mode_pomodoro');
      var modeSw = document.getElementById('mode_stopwatch');
      var pomoSec = document.getElementById('pomodoro_section');
      var swSec = document.getElementById('stopwatch_section');

      modePomo.onclick = function() {
        isStopwatch = false;
        modePomo.style.background = '#0D5CE5';
        modePomo.style.color = '#FFF';
        modeSw.style.background = 'transparent';
        modeSw.style.color = '#64748B';
        pomoSec.style.display = 'block';
        swSec.style.display = 'none';
      };

      modeSw.onclick = function() {
        isStopwatch = true;
        modeSw.style.background = '#0D5CE5';
        modeSw.style.color = '#FFF';
        modePomo.style.background = 'transparent';
        modePomo.style.color = '#64748B';
        swSec.style.display = 'block';
        pomoSec.style.display = 'none';
      };

      var btnPomoStart = document.getElementById('btn_pomo_start');
      var btnPomoReset = document.getElementById('btn_pomo_reset');
      var pomoDisplay = document.getElementById('pomo_timer_display');

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

      document.querySelectorAll('.pomo_preset').forEach(function(btn) {
        btn.onclick = function() {
          document.querySelectorAll('.pomo_preset').forEach(function(b) {
            b.style.background = 'transparent';
            b.style.color = 'inherit';
          });
          btn.style.background = '#0D5CE5';
          btn.style.color = 'white';
          var m = parseInt(btn.getAttribute('data-min'));
          totalSec = m * 60;
          remainingSec = totalSec;
          pomoDisplay.innerText = formatTime(remainingSec);
          if (isRunning) {
            clearInterval(timerId);
            isRunning = false;
            btnPomoStart.innerText = 'Start';
            btnPomoStart.style.background = '#0D5CE5';
          }
        };
      });

      var btnSwStart = document.getElementById('btn_sw_start');
      var btnSwLap = document.getElementById('btn_sw_lap');
      var btnSwReset = document.getElementById('btn_sw_reset');
      var swDisplay = document.getElementById('sw_timer_display');
      var lapsCont = document.getElementById('sw_laps_container');

      btnSwStart.onclick = function() {
        if (!swRunning) {
          swRunning = true;
          btnSwStart.innerText = 'Pause';
          btnSwStart.style.background = '#EF4444';
          swTimerId = setInterval(function() {
            swElapsed++;
            swDisplay.innerText = formatStopwatch(swElapsed);
          }, 10);
        } else {
          clearInterval(swTimerId);
          swRunning = false;
          btnSwStart.innerText = 'Resume';
          btnSwStart.style.background = '#0D5CE5';
        }
      };

      btnSwLap.onclick = function() {
        if (swElapsed > 0) {
          swLaps.unshift(formatStopwatch(swElapsed));
          lapsCont.innerHTML = swLaps.map(function(l, i) {
            return '<div style="display:flex; justify-content:space-between; padding:4px 8px; font-size:13px; font-weight:600; border-bottom:1px solid #E2E8F0;"><span>Lap ' + (swLaps.length - i) + '</span><span>' + l + '</span></div>';
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
        lapsCont.innerHTML = '<div style="font-size: 12px; color: #94A3B8; text-align: center;">No laps recorded yet</div>';
      };
    } catch(err) {
      console.error('[FOCUS MODAL ERROR]:', err);
    }
  };

  // --- GOALS MANAGEMENT MODAL ---
  window._openGoalsModal = window._openGoalPyramidModal = function(ctx) {
    try {
      var isDark = getIsDark(ctx);
      var existingOverlay = document.getElementById('wrindha_goal_modal');
      if (existingOverlay) existingOverlay.remove();

      if (!window._wrindhaGoals) {
        window._wrindhaGoals = {
          short: [
            { id: 'g_s1', title: 'Complete Calculus Assignment #4', targetDate: 'This Friday', isDone: false },
            { id: 'g_s2', title: 'Read Chapter 5: Organic Chemistry', targetDate: 'Tomorrow', isDone: true }
          ],
          medium: [
            { id: 'g_m1', title: 'Achieve Grade A in Midterm Exams', targetDate: 'End of Semester', isDone: false },
            { id: 'g_m2', title: 'Build Full-Stack Project Portfolio', targetDate: 'Next Month', isDone: false }
          ],
          long: [
            { id: 'g_l1', title: 'Land Software Engineering Role', targetDate: 'Graduation 2027', isDone: false },
            { id: 'g_l2', title: 'Graduate with First Class Honors (GPA 3.8+)', targetDate: 'Final Year', isDone: false }
          ]
        };
      }

      var defaultGoals = window._wrindhaGoals;
      var overlay = document.createElement('div');
      overlay.id = 'wrindha_goal_modal';
      overlay.style.position = 'fixed';
      overlay.style.top = '0';
      overlay.style.left = '0';
      overlay.style.width = '100vw';
      overlay.style.height = '100vh';
      overlay.style.backgroundColor = 'rgba(15, 23, 42, 0.75)';
      overlay.style.backdropFilter = 'blur(10px)';
      overlay.style.zIndex = '999999';
      overlay.style.display = 'flex';
      overlay.style.justifyContent = 'center';
      overlay.style.alignItems = 'center';
      overlay.style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';

      var activeTab = 'short';

      function renderModal() {
        var goals = defaultGoals[activeTab] || [];
        overlay.innerHTML = `
          <div style="background: ${isDark ? '#1E1F2B' : '#FFF9F0'}; color: ${isDark ? '#FFF' : '#1E293B'}; width: 90%; max-width: 500px; border-radius: 28px; padding: 28px; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.35); border: 1px solid ${isDark ? '#2D2F3F' : '#E2E8F0'}; max-height: 90vh; overflow-y: auto;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
              <div style="display: flex; align-items: center; gap: 10px;">
                <div style="background: #E87552; color: white; width: 38px; height: 38px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 20px;">🎯</div>
                <div>
                  <h2 style="margin: 0; font-size: 19px; font-weight: 800;">Goals</h2>
                  <p style="margin: 0; font-size: 12px; color: #64748B;">Short-Term, Medium-Term & Long-Term</p>
                </div>
              </div>
              <button id="close_goal_modal" style="background: transparent; border: none; font-size: 24px; cursor: pointer; color: #94A3B8;">&times;</button>
            </div>

            <!-- Tier Tabs -->
            <div style="display: flex; background: ${isDark ? '#14151F' : '#E2E8F0'}; border-radius: 14px; padding: 4px; margin-bottom: 20px;">
              <button id="tab_short" style="flex: 1; padding: 9px; border: none; border-radius: 10px; font-weight: 700; font-size: 13px; cursor: pointer; background: ${activeTab === 'short' ? '#E87552' : 'transparent'}; color: ${activeTab === 'short' ? '#FFF' : '#64748B'};">⚡ Short-Term</button>
              <button id="tab_medium" style="flex: 1; padding: 9px; border: none; border-radius: 10px; font-weight: 700; font-size: 13px; cursor: pointer; background: ${activeTab === 'medium' ? '#E87552' : 'transparent'}; color: ${activeTab === 'medium' ? '#FFF' : '#64748B'};">📅 Medium-Term</button>
              <button id="tab_long" style="flex: 1; padding: 9px; border: none; border-radius: 10px; font-weight: 700; font-size: 13px; cursor: pointer; background: ${activeTab === 'long' ? '#E87552' : 'transparent'}; color: ${activeTab === 'long' ? '#FFF' : '#64748B'};">🏔️ Long-Term</button>
            </div>

            <!-- Add Goal Input -->
            <div style="display: flex; gap: 8px; margin-bottom: 18px;">
              <input id="input_goal_title" type="text" placeholder="Add a new goal..." style="flex: 1; padding: 12px 14px; border-radius: 12px; border: 1px solid ${isDark ? '#3E4155' : '#CBD5E1'}; background: ${isDark ? '#14151F' : '#FFF'}; color: inherit; font-size: 14px; outline: none;" />
              <button id="btn_add_goal" style="background: #E87552; color: white; border: none; padding: 12px 18px; border-radius: 12px; font-weight: 800; cursor: pointer;">+ Add Goal</button>
            </div>

            <!-- Goals List -->
            <div id="goals_list_container">
              ${goals.length === 0 ? '<div style="text-align:center; padding:24px; color:#94A3B8; font-size:13px;">No goals added in this category yet.</div>' : ''}
              ${goals.map(function(g, idx) {
                return `
                  <div style="display: flex; align-items: center; justify-content: space-between; background: ${isDark ? '#14151F' : '#FFFFFF'}; padding: 14px 16px; border-radius: 16px; margin-bottom: 10px; border: 1px solid ${isDark ? '#2A2C3E' : '#E2E8F0'};">
                    <div style="display: flex; align-items: center; gap: 12px;">
                      <input type="checkbox" class="goal_checkbox" data-idx="${idx}" ${g.isDone ? 'checked' : ''} style="width: 18px; height: 18px; cursor: pointer; accent-color: #E87552;" />
                      <div>
                        <div style="font-weight: 700; font-size: 14px; text-decoration: ${g.isDone ? 'line-through' : 'none'}; color: ${g.isDone ? '#94A3B8' : 'inherit'};">${g.title}</div>
                        <div style="font-size: 11px; color: #94A3B8;">Target: ${g.targetDate}</div>
                      </div>
                    </div>
                    <button class="goal_delete" data-idx="${idx}" style="background: transparent; border: none; color: #EF4444; font-size: 18px; cursor: pointer;">&times;</button>
                  </div>
                `;
              }).join('')}
            </div>
          </div>
        `;

        document.getElementById('close_goal_modal').onclick = function() { overlay.remove(); };
        document.getElementById('tab_short').onclick = function() { activeTab = 'short'; renderModal(); };
        document.getElementById('tab_medium').onclick = function() { activeTab = 'medium'; renderModal(); };
        document.getElementById('tab_long').onclick = function() { activeTab = 'long'; renderModal(); };

        document.getElementById('btn_add_goal').onclick = function() {
          var input = document.getElementById('input_goal_title');
          var val = input.value.trim();
          if (val) {
            defaultGoals[activeTab].push({
              id: 'g_' + Date.now(),
              title: val,
              targetDate: activeTab === 'short' ? 'This Week' : activeTab === 'medium' ? 'This Quarter' : 'Vision Target',
              isDone: false
            });
            renderModal();
          }
        };

        document.querySelectorAll('.goal_checkbox').forEach(function(cb) {
          cb.onchange = function() {
            var idx = parseInt(cb.getAttribute('data-idx'));
            defaultGoals[activeTab][idx].isDone = cb.checked;
            renderModal();
          };
        });

        document.querySelectorAll('.goal_delete').forEach(function(btn) {
          btn.onclick = function() {
            var idx = parseInt(btn.getAttribute('data-idx'));
            defaultGoals[activeTab].splice(idx, 1);
            renderModal();
          };
        });
      }

      renderModal();
      document.body.appendChild(overlay);
    } catch(err) {
      console.error('[GOALS MODAL ERROR]:', err);
    }
  };

  // --- SUBJECT CURRICULUM UNITS & TOPICS MODAL ---
  window._openSubjectUnitsModal = function(ctx, subject) {
    try {
      var isDark = getIsDark(ctx);
      var existingOverlay = document.getElementById('wrindha_subject_modal');
      if (existingOverlay) existingOverlay.remove();

      var subjName = (subject && subject.b) ? subject.b : 'Academic Subject';

      if (!subject.unitsList) {
        subject.unitsList = [
          {
            title: 'Unit 1: Fundamentals & Concepts',
            topics: [
              { title: 'Core Principles & Theory', isDone: true },
              { title: 'Problem Solving & Exercises', isDone: true },
              { title: 'Practice Problems & Review', isDone: false }
            ]
          },
          {
            title: 'Unit 2: Advanced Topics & Applications',
            topics: [
              { title: 'Case Studies & Analysis', isDone: false },
              { title: 'Exam Preparation & Mastery', isDone: false }
            ]
          }
        ];
      }

      function calculateMastery() {
        var totalTopics = 0;
        var completedTopics = 0;
        subject.unitsList.forEach(function(u) {
          u.topics.forEach(function(t) {
            totalTopics++;
            if (t.isDone) completedTopics++;
          });
        });
        return totalTopics === 0 ? 0 : Math.round((completedTopics / totalTopics) * 100);
      }

      var overlay = document.createElement('div');
      overlay.id = 'wrindha_subject_modal';
      overlay.style.position = 'fixed';
      overlay.style.top = '0';
      overlay.style.left = '0';
      overlay.style.width = '100vw';
      overlay.style.height = '100vh';
      overlay.style.backgroundColor = 'rgba(15, 23, 42, 0.75)';
      overlay.style.backdropFilter = 'blur(10px)';
      overlay.style.zIndex = '999999';
      overlay.style.display = 'flex';
      overlay.style.justifyContent = 'center';
      overlay.style.alignItems = 'center';
      overlay.style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';

      function renderSubjectModal() {
        var pct = calculateMastery();
        if (subject) subject.e = pct / 100;

        overlay.innerHTML = `
          <div style="background: ${isDark ? '#1E1F2B' : '#FFF9F0'}; color: ${isDark ? '#FFF' : '#1E293B'}; width: 90%; max-width: 520px; border-radius: 28px; padding: 28px; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.35); border: 1px solid ${isDark ? '#2D2F3F' : '#E2E8F0'}; max-height: 90vh; overflow-y: auto;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
              <div style="display: flex; align-items: center; gap: 12px;">
                <div style="background: #0D5CE5; color: white; width: 40px; height: 40px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 20px;">📚</div>
                <div>
                  <h2 style="margin: 0; font-size: 19px; font-weight: 800;">${subjName}</h2>
                  <p style="margin: 0; font-size: 12px; color: #64748B;">Curriculum Units & Topics</p>
                </div>
              </div>
              <button id="close_subject_modal" style="background: transparent; border: none; font-size: 24px; cursor: pointer; color: #94A3B8;">&times;</button>
            </div>

            <!-- Mastery Card -->
            <div style="background: ${isDark ? '#14151F' : '#EEF2FF'}; padding: 18px; border-radius: 18px; margin-bottom: 20px; border: 1px solid ${isDark ? '#242638' : '#C7D2FE'};">
              <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                <span style="font-size: 11px; font-weight: 800; letter-spacing: 1px; color: #64748B; text-transform: uppercase;">MASTERY PROGRESS</span>
                <span style="font-size: 20px; font-weight: 900; color: #0D5CE5;">${pct}%</span>
              </div>
              <div style="background: ${isDark ? '#2A2C3E' : '#E0E7FF'}; height: 8px; border-radius: 4px; overflow: hidden;">
                <div style="background: #0D5CE5; height: 100%; width: ${pct}%; border-radius: 4px; transition: width 0.3s ease;"></div>
              </div>
              <button id="btn_modal_focus" style="width: 100%; margin-top: 14px; background: #0D5CE5; color: white; border: none; padding: 10px; border-radius: 12px; font-weight: 700; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 8px;">⏱️ Start Deep Focus Session</button>
            </div>

            <!-- Add Unit Form -->
            <div style="display: flex; gap: 8px; margin-bottom: 18px;">
              <input id="input_unit_title" type="text" placeholder="Add new unit (e.g. Unit 3: Thermodynamics)..." style="flex: 1; padding: 11px 14px; border-radius: 12px; border: 1px solid ${isDark ? '#3E4155' : '#CBD5E1'}; background: ${isDark ? '#14151F' : '#FFF'}; color: inherit; font-size: 13px; outline: none;" />
              <button id="btn_add_unit" style="background: #0D5CE5; color: white; border: none; padding: 11px 16px; border-radius: 12px; font-weight: 800; cursor: pointer;">+ Add Unit</button>
            </div>

            <!-- Units & Topics List -->
            <div id="units_container">
              ${subject.unitsList.map(function(u, uIdx) {
                return `
                  <div style="background: ${isDark ? '#14151F' : '#FFFFFF'}; border-radius: 16px; padding: 16px; margin-bottom: 14px; border: 1px solid ${isDark ? '#2A2C3E' : '#E2E8F0'};">
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
                      <h4 style="margin: 0; font-size: 15px; font-weight: 800;">${u.title}</h4>
                      <button class="btn_add_topic_to_unit" data-uidx="${uIdx}" style="background: #EEF2FF; color: #0D5CE5; border: 1px solid #C7D2FE; border-radius: 8px; padding: 4px 8px; font-size: 11px; font-weight: 700; cursor: pointer;">+ Topic</button>
                    </div>
                    <div style="display: flex; flex-direction: column; gap: 8px;">
                      ${u.topics.map(function(t, tIdx) {
                        return `
                          <label style="display: flex; align-items: center; gap: 10px; cursor: pointer; padding: 6px 8px; border-radius: 8px; background: ${isDark ? '#1E1F2B' : '#F8FAFC'};">
                            <input type="checkbox" class="topic_cb" data-uidx="${uIdx}" data-tidx="${tIdx}" ${t.isDone ? 'checked' : ''} style="width: 16px; height: 16px; accent-color: #0D5CE5; cursor: pointer;" />
                            <span style="font-size: 13px; font-weight: 600; text-decoration: ${t.isDone ? 'line-through' : 'none'}; color: ${t.isDone ? '#94A3B8' : 'inherit'};">${t.title}</span>
                          </label>
                        `;
                      }).join('')}
                    </div>
                  </div>
                `;
              }).join('')}
            </div>
          </div>
        `;

        document.getElementById('close_subject_modal').onclick = function() { overlay.remove(); };
        document.getElementById('btn_modal_focus').onclick = function() {
          overlay.remove();
          window._openFocusTimerModal(ctx);
        };

        document.getElementById('btn_add_unit').onclick = function() {
          var input = document.getElementById('input_unit_title');
          var val = input.value.trim();
          if (val) {
            subject.unitsList.push({
              title: val,
              topics: [
                { title: 'Chapter Overview & Key Points', isDone: false },
                { title: 'Exercises & Practice', isDone: false }
              ]
            });
            renderSubjectModal();
          }
        };

        document.querySelectorAll('.btn_add_topic_to_unit').forEach(function(btn) {
          btn.onclick = function() {
            var uIdx = parseInt(btn.getAttribute('data-uidx'));
            var title = prompt('Enter topic title:');
            if (title && title.trim()) {
              subject.unitsList[uIdx].topics.push({ title: title.trim(), isDone: false });
              renderSubjectModal();
            }
          };
        });

        document.querySelectorAll('.topic_cb').forEach(function(cb) {
          cb.onchange = function() {
            var uIdx = parseInt(cb.getAttribute('data-uidx'));
            var tIdx = parseInt(cb.getAttribute('data-tidx'));
            subject.unitsList[uIdx].topics[tIdx].isDone = cb.checked;
            renderSubjectModal();
          };
        });
      }

      renderSubjectModal();
      document.body.appendChild(overlay);
    } catch(err) {
      console.error('[SUBJECT UNITS MODAL ERROR]:', err);
    }
  };
})();
