/* ==========================================================================
   IRON HAVEN — assets/js/forms.js
   Pricing toggle, demo form validation, back-to-top and year stamps.
   ========================================================================== */
(function () {
  'use strict';

  const { $, $$, reduceMotion } = window.IronHaven;
  if (!$) return; // main.js failed to load — nothing to enhance.

  /* ------------------------------------------------------------------
   * Pricing billing toggle (monthly <-> annual)
   * ---------------------------------------------------------------- */
  function initBillingToggle() {
    const toggle = $('[data-billing-toggle]');
    if (!toggle) return;
    const buttons = $$('[data-billing]', toggle);

    const apply = (cycle) => {
      buttons.forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.billing === cycle)));

      $$('[data-price-monthly]').forEach((el) => {
        const card = el.closest('.price-card');
        const target = cycle === 'annual' ? el.dataset.priceAnnual : el.dataset.priceMonthly;
        const note = card ? $('[data-price-note]', card) : null;

        if (card) card.classList.add('is-switching');
        // Short crossfade so the number change reads as deliberate.
        setTimeout(() => {
          el.textContent = target;
          if (note) note.textContent = cycle === 'annual' ? 'billed annually' : 'billed monthly';
          if (card) card.classList.remove('is-switching');
        }, 140);
      });
    };

    toggle.addEventListener('click', (e) => {
      const btn = e.target.closest('[data-billing]');
      if (btn) apply(btn.dataset.billing);
    });
  }

  /* ------------------------------------------------------------------
   * Demo form validation
   * NOTE: this only validates in the browser for UX. Wire the submit
   * handler to a real endpoint before going live.
   * ---------------------------------------------------------------- */
  function initForms() {
    $$('[data-validate]').forEach((form) => {
      const status = $('[data-form-status]', form);

      const validateField = (field) => {
        const input = $('input, select, textarea', field);
        if (!input || !input.required) return true;
        const value = input.value.trim();
        let valid = value.length > 0;

        if (valid && input.type === 'email') {
          valid = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(value);
        }
        if (valid && input.type === 'tel') {
          valid = value.replace(/\D/g, '').length >= 7;
        }

        field.classList.toggle('field--error', !valid);
        input.setAttribute('aria-invalid', String(!valid));
        return valid;
      };

      $$('.field', form).forEach((field) => {
        const input = $('input, select, textarea', field);
        if (!input) return;
        input.addEventListener('blur', () => validateField(field));
        input.addEventListener('input', () => {
          if (field.classList.contains('field--error')) validateField(field);
        });
      });

      form.addEventListener('submit', (e) => {
        e.preventDefault();
        const allValid = $$('.field', form).map(validateField).every(Boolean);
        if (!status) return;

        if (allValid) {
          status.className = 'form__status is-success';
          status.setAttribute('role', 'status');
          status.textContent = 'Thanks! Your request is in — our team replies within 24 hours.';
          form.reset();
        } else {
          status.className = 'form__status is-error';
          status.setAttribute('role', 'alert');
          status.textContent = 'Please check the highlighted fields and try again.';
          const firstError = $('.field--error input, .field--error select, .field--error textarea', form);
          if (firstError) firstError.focus();
        }
      });
    });
  }

  /* ------------------------------------------------------------------
   * Back-to-top button and automatic year stamps
   * ---------------------------------------------------------------- */
  function initMisc() {
    const toTop = $('.to-top');
    if (toTop) {
      const onScroll = () => toTop.classList.toggle('is-visible', window.scrollY > 600);
      onScroll();
      window.addEventListener('scroll', onScroll, { passive: true });
      toTop.addEventListener('click', () => {
        window.scrollTo({ top: 0, behavior: reduceMotion ? 'auto' : 'smooth' });
      });
    }

    $$('[data-year]').forEach((el) => {
      el.textContent = new Date().getFullYear();
    });
  }

  function init() {
    initBillingToggle();
    initForms();
    initMisc();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();