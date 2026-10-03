/* ==========================================================================
   IRON HAVEN — assets/js/main.js (core)
   Vanilla JS, no dependencies. Every feature is progressive-enhancement
   only: the site stays fully usable if this file fails to load.
   ========================================================================== */
(function () {
  'use strict';

  const $ = (sel, ctx) => (ctx || document).querySelector(sel);
  const $$ = (sel, ctx) => Array.from((ctx || document).querySelectorAll(sel));
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ------------------------------------------------------------------
   * 1. Sticky header state
   * ---------------------------------------------------------------- */
  function initStickyHeader() {
    const header = $('.site-header');
    if (!header) return;
    const onScroll = () => header.classList.toggle('is-stuck', window.scrollY > 12);
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
  }

  /* ------------------------------------------------------------------
   * 2. Mobile navigation drawer
   * ---------------------------------------------------------------- */
  function initMobileNav() {
    const toggle = $('.nav-toggle');
    const nav = $('#primary-nav');
    if (!toggle || !nav) return;

    const setOpen = (open) => {
      toggle.setAttribute('aria-expanded', String(open));
      nav.classList.toggle('is-open', open);
      document.body.style.overflow = open ? 'hidden' : '';
    };

    toggle.addEventListener('click', () => {
      setOpen(toggle.getAttribute('aria-expanded') !== 'true');
    });

    // Close on link activation, Escape, or resize back to desktop.
    nav.addEventListener('click', (e) => {
      if (e.target.closest('a')) setOpen(false);
    });
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && toggle.getAttribute('aria-expanded') === 'true') {
        setOpen(false);
        toggle.focus();
      }
    });
    window.addEventListener('resize', () => {
      if (window.innerWidth > 960) setOpen(false);
    });
  }

  /* ------------------------------------------------------------------
   * 3. Scroll reveal
   * ---------------------------------------------------------------- */
  function initReveal() {
    const items = $$('[data-reveal]');
    if (!items.length) return;

    if (reduceMotion || !('IntersectionObserver' in window)) {
      items.forEach((el) => el.classList.add('is-visible'));
      return;
    }

    const io = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add('is-visible');
        io.unobserve(entry.target);
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });

    items.forEach((el) => io.observe(el));
  }

  /* ------------------------------------------------------------------
   * 4. Animated counters
   * ---------------------------------------------------------------- */
  function initCounters() {
    const counters = $$('[data-count]');
    if (!counters.length) return;

    const run = (el) => {
      const target = parseFloat(el.getAttribute('data-count'));
      const decimals = parseInt(el.getAttribute('data-decimals') || '0', 10);
      const duration = 1400;

      if (reduceMotion) {
        el.textContent = target.toFixed(decimals);
        return;
      }

      const start = performance.now();
      const tick = (now) => {
        const p = Math.min((now - start) / duration, 1);
        const eased = 1 - Math.pow(1 - p, 3);
        el.textContent = (target * eased).toFixed(decimals);
        if (p < 1) requestAnimationFrame(tick);
      };
      requestAnimationFrame(tick);
    };

    if (!('IntersectionObserver' in window)) {
      counters.forEach(run);
      return;
    }

    const io = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        run(entry.target);
        io.unobserve(entry.target);
      });
    }, { threshold: 0.5 });

    counters.forEach((el) => io.observe(el));
  }

  /* ---------------------------------------------------------------- */
  function init() {
    initStickyHeader();
    initMobileNav();
    initReveal();
    initCounters();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  // Exposed so the feature modules can share the same helpers.
  window.IronHaven = { $, $$, reduceMotion };
})();