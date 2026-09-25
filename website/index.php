<?php
/**
 * Main Template File for Tuition Fee eCommerce Theme
 *
 * @package TuitionFee
 * @version 1.1.0
 */

// If accessed as a WordPress template, output header and content
?>
<!DOCTYPE html>
<html <?php language_attributes(); ?>>
<head>
  <meta charset="<?php bloginfo('charset'); ?>">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><?php bloginfo('name'); ?> - Subscription Plans & Store</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <script src="https://cdn.tailwindcss.com"></script>
  <script>
    tailwind.config = {
      theme: {
        extend: {
          fontFamily: {
            sans: ['"Plus Jakarta Sans"', 'sans-serif'],
          },
          colors: {
            brand: {
              50: '#f5f3ff',
              100: '#ede9fe',
              500: '#6366f1',
              600: '#4f46e5',
              700: '#4338ca',
            },
            accent: '#f59e0b',
            bkash: '#e2136e',
            nagad: '#f7941d'
          }
        }
      }
    }
  </script>
  <style>
    .glass-card {
      background: rgba(255, 255, 255, 0.95);
      backdrop-filter: blur(12px);
      border: 1px solid rgba(229, 231, 235, 0.8);
    }
    .gradient-bg {
      background: radial-gradient(circle at top right, #e0e7ff 0%, #f8fafc 50%, #f1f5f9 100%);
    }
  </style>
  <?php wp_head(); ?>
</head>
<body <?php body_class('bg-slate-50 text-slate-900 font-sans antialiased min-h-screen flex flex-col'); ?>>

  <!-- TOP NAVIGATION -->
  <header class="sticky top-0 z-40 bg-white/90 backdrop-blur-md border-b border-slate-200">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-20 flex items-center justify-between">
      <div class="flex items-center space-x-3">
        <div class="w-11 h-11 rounded-xl bg-gradient-to-tr from-brand-600 to-indigo-500 flex items-center justify-center text-white shadow-md shadow-brand-500/20">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"></path>
          </svg>
        </div>
        <div>
          <span class="text-xl font-extrabold tracking-tight text-slate-900"><?php bloginfo('name'); ?></span>
          <span class="text-xs ml-1.5 px-2 py-0.5 rounded-full bg-brand-50 text-brand-600 font-bold border border-brand-100">PRO v1.1.0</span>
        </div>
      </div>

      <div class="flex items-center space-x-4">
        <a href="#pricing" class="px-5 py-2.5 text-sm font-bold text-white bg-brand-600 hover:bg-brand-700 rounded-xl shadow-lg shadow-brand-500/25 transition">
          Purchase Plans
        </a>
      </div>
    </div>
  </header>

  <!-- HERO -->
  <section class="gradient-bg py-20 relative overflow-hidden border-b border-slate-200 text-center">
    <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="inline-flex items-center space-x-2 px-4 py-1.5 rounded-full bg-indigo-50 border border-indigo-200 text-indigo-700 text-xs font-bold uppercase tracking-wider mb-6">
        <span>🎉 Free Tier: Up to 5 Batches & 10 Students Free</span>
      </div>
      <h1 class="text-4xl sm:text-6xl font-black text-slate-900 tracking-tight leading-tight">
        Manage Batches & Students with <span class="text-transparent bg-clip-text bg-gradient-to-r from-brand-600 to-indigo-600">Flexible Plans</span>
      </h1>
      <p class="mt-6 text-lg text-slate-600 max-w-2xl mx-auto">
        Buy subscription plans for 1 month or multiple months using bKash, Nagad, or Cards. Unlock instant unlimited capacity.
      </p>
    </div>
  </section>

  <!-- PRICING SECTION -->
  <section id="pricing" class="py-20 bg-slate-50">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="text-center max-w-3xl mx-auto mb-12">
        <h2 class="text-xs font-extrabold uppercase tracking-widest text-brand-600 mb-3">Subscription Plans</h2>
        <h3 class="text-3xl sm:text-4xl font-black text-slate-900">Choose Your Ideal Plan</h3>

        <!-- Duration Selector -->
        <div class="mt-8 inline-flex items-center p-1.5 rounded-2xl bg-white border border-slate-200 shadow-sm">
          <button type="button" onclick="selectDuration(1)" id="btn-month-1" class="duration-btn px-5 py-2 rounded-xl text-sm font-bold bg-brand-600 text-white shadow-sm transition">
            1 Month
          </button>
          <button type="button" onclick="selectDuration(3)" id="btn-month-3" class="duration-btn px-5 py-2 rounded-xl text-sm font-semibold text-slate-600 hover:text-slate-900 transition">
            3 Months <span class="ml-1 text-xs text-emerald-600 font-bold bg-emerald-50 px-1.5 py-0.5 rounded">Save 5%</span>
          </button>
          <button type="button" onclick="selectDuration(6)" id="btn-month-6" class="duration-btn px-5 py-2 rounded-xl text-sm font-semibold text-slate-600 hover:text-slate-900 transition">
            6 Months <span class="ml-1 text-xs text-emerald-600 font-bold bg-emerald-50 px-1.5 py-0.5 rounded">Save 10%</span>
          </button>
          <button type="button" onclick="selectDuration(12)" id="btn-month-12" class="duration-btn px-5 py-2 rounded-xl text-sm font-semibold text-slate-600 hover:text-slate-900 transition">
            12 Months <span class="ml-1 text-xs text-brand-600 font-bold bg-brand-50 px-1.5 py-0.5 rounded">Save 20%</span>
          </button>
        </div>
      </div>

      <div id="pricing-cards" class="grid grid-cols-1 md:grid-cols-3 gap-8 items-stretch">
        <!-- Rendered by JS or PHP -->
      </div>
    </div>
  </section>

  <!-- Include checkout modal & JS from static store -->
  <?php include __DIR__ . '/index.html'; ?>

  <?php wp_footer(); ?>
</body>
</html>
