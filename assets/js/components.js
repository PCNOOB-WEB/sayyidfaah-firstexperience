/* ==========================================================================
   IRON HAVEN — assets/js/components.js
   Interactive components: tabs, accordions, slider, pricing toggle,
   forms and small utilities. Depends on helpers exported by main.js.
   ========================================================================== */
(function () {
  'use strict';

  const { $, $$, reduceMotion } = window.IronHaven;
  if (!$) return; // main.js failed to load — nothing to enhance.

  /* ------------------------------------------------------------------
   * Tabs (program filtering) — WAI-ARIA tabs pattern with arrow keys
   * ---------------------------------------------------------------- */
  function initTabs() {
    $$('[role="tablist"]').forEach((tablist) => {
      const tabs = $$('[role="tab"]', tablist);

      const select = (tab) => {
        tabs.forEach((t) => {
          const isActive = t === tab;
          t.setAttribute('aria-selected', String(isActive));
          t.tabIndex = isActive ? 0 : -1;
          const panel = document.getElementById(t.getAttribute('aria-controls'));
          if (panel) panel.hidden = !isActive;
        });
      };

      tablist.addEventListener('click', (e) => {
        const tab = e.target.closest('[role="tab"]');
        if (tab) select(tab);
      });

      tablist.addEventListener('keydown', (e) => {
        const idx = tabs.indexOf(document.activeElement);
        if (idx === -1) return;
        let next = null;
        if (e.key === 'ArrowRight') next = tabs[(idx + 1) % tabs.length];
        if (e.key === 'ArrowLeft') next = tabs[(idx - 1 + tabs.length) % tabs.length];
        if (e.key === 'Home') next = tabs[0];
        if (e.key === 'End') next = tabs[tabs.length - 1];
        if (!next) return;
        e.preventDefault();
        next.focus();
        select(next);
      });
    });
  }

  /* ------------------------------------------------------------------
   * Accordion — animated height, optional single-open behaviour
   * ---------------------------------------------------------------- */
  function initAccordions() {
    $$('[data-accordion]').forEach((root) => {
      const items = $$('.accordion__item', root);
      const single = root.hasAttribute('data-accordion-single');

      const setOpen = (item, open) => {
        const trigger = $('.accordion__trigger', item);
        const panel = $('.accordion__panel', item);
        if (!trigger || !panel) return;
        item.classList.toggle('is-open', open);
        trigger.setAttribute('aria-expanded', String(open));
        panel.style.height = open ? panel.scrollHeight + 'px' : '0px';
      };

      items.forEach((item) => {
        const trigger = $('.accordion__trigger', item);
        if (!trigger) return;
        setOpen(item, item.classList.contains('is-open'));

        trigger.addEventListener('click', () => {
          const willOpen = !item.classList.contains('is-open');
          if (single && willOpen) {
            items.forEach((other) => {
              if (other !== item) setOpen(other, false);
            });
          }
          setOpen(item, willOpen);
        });
      });

      // Re-measure open panels when the viewport reflows their text.
      window.addEventListener('resize', () => {
        items.forEach((item) => {
          if (item.classList.contains('is-open')) setOpen(item, true);
        });
      });
    });
  }

  /* ------------------------------------------------------------------
   * Testimonial slider — autoplay, dots, keyboard, restarts on input
   * ---------------------------------------------------------------- */
  function initSliders() {
    $$('[data-slider]').forEach((root) => {
      const track = $('.slider__track', root);
      const slides = $$('.slider__slide', root);
      if (!track || !slides.length) return;

      const prev = $('[data-slider-prev]', root);
      const next = $('[data-slider-next]', root);
      const dotsWrap = $('[data-slider-dots]', root);
      let index = 0;
      let timer = null;

      const dots = slides.map((_, i) => {
        const dot = document.createElement('button');
        dot.type = 'button';
        dot.className = 'slider__dot';
        dot.setAttribute('aria-label', 'Go to testimonial ' + (i + 1));
        dot.addEventListener('click', () => {
          goTo(i);
          restart();
        });
        if (dotsWrap) dotsWrap.appendChild(dot);
        return dot;
      });

      const goTo = (i) => {
        index = (i + slides.length) % slides.length;
        track.style.transform = 'translateX(' + -index * 100 + '%)';
        dots.forEach((d, n) => d.setAttribute('aria-current', String(n === index)));
        slides.forEach((s, n) => {
          // Keep off-screen slides out of the tab order.
          s.setAttribute('aria-hidden', String(n !== index));
          $$('a, button', s).forEach((el) => {
            if (n === index) el.removeAttribute('tabindex');
            else el.setAttribute('tabindex', '-1');
          });
        });
      };

      const restart = () => {
        if (reduceMotion) return;
        clearInterval(timer);
        timer = setInterval(() => goTo(index + 1), 7000);
      };

      if (prev) prev.addEventListener('click', () => { goTo(index - 1); restart(); });
      if (next) next.addEventListener('click', () => { goTo(index + 1); restart(); });

      goTo(0);
      restart();
    });
  }

  function init() {
    initTabs();
    initAccordions();
    initSliders();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();