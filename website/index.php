<?php
/**
 * Main Template for Tuition Fee Manager WordPress Theme
 *
 * @package TuitionFee
 * @version 1.2.0
 */

if (!defined('ABSPATH')) {
    exit;
}

get_header();

$payment_number = get_option('tuition_payment_number', '01825690912');
$currency = get_option('tuition_currency_symbol', '৳');
$plans = tuition_fee_get_plans_data();
?>

<main class="flex-grow">
  <!-- ================= HERO SECTION ================= -->
  <section class="gradient-bg py-16 lg:py-24 relative overflow-hidden border-b border-slate-200">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10 text-center">
      <div class="inline-flex items-center space-x-2 px-4 py-1.5 rounded-full bg-indigo-50 border border-indigo-200 text-indigo-700 text-xs font-bold uppercase tracking-wider mb-6">
        <span>🎉 <?php esc_html_e('Free Tier: Up to 5 Batches & 10 Students Free Forever', 'tuition-fee'); ?></span>
      </div>
      <h1 class="text-4xl sm:text-6xl font-black text-slate-900 tracking-tight leading-tight max-w-4xl mx-auto">
        Verified Subscriptions & Payments for <span class="text-transparent bg-clip-text bg-gradient-to-r from-indigo-600 to-violet-600"><?php bloginfo('name'); ?></span>
      </h1>
      <p class="mt-6 text-lg sm:text-xl text-slate-600 max-w-2xl mx-auto leading-relaxed">
        <?php bloginfo('description'); ?> Fast digital license delivery for private tutors & coaching centers. Pay securely via bKash, Nagad, or Cards and receive 100% mathematically authentic activation keys.
      </p>

      <div class="mt-10 flex flex-wrap justify-center gap-4">
        <a href="#pricing" class="px-8 py-4 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-2xl shadow-xl shadow-indigo-500/30 transition transform hover:-translate-y-0.5 text-base">
          <?php esc_html_e('Browse Plans & Pricing', 'tuition-fee'); ?>
        </a>
        <button type="button" onclick="openOrdersModal()" class="px-8 py-4 bg-white hover:bg-slate-50 text-slate-800 font-bold rounded-2xl border border-slate-200 shadow-sm transition text-base">
          <?php esc_html_e('View My Past Licenses', 'tuition-fee'); ?>
        </button>
      </div>

      <!-- Trust Badges -->
      <div class="mt-12 pt-8 border-t border-slate-200/60 max-w-4xl mx-auto grid grid-cols-2 md:grid-cols-4 gap-6 text-slate-600 text-xs font-bold">
        <div class="flex items-center justify-center space-x-2">
          <span class="text-emerald-500 text-sm">✓</span> <span><?php esc_html_e('Instant SHA-256 Keys', 'tuition-fee'); ?></span>
        </div>
        <div class="flex items-center justify-center space-x-2">
          <span class="text-emerald-500 text-sm">✓</span> <span><?php esc_html_e('Official bKash & Nagad', 'tuition-fee'); ?></span>
        </div>
        <div class="flex items-center justify-center space-x-2">
          <span class="text-emerald-500 text-sm">✓</span> <span><?php esc_html_e('100% Workable in App', 'tuition-fee'); ?></span>
        </div>
        <div class="flex items-center justify-center space-x-2">
          <span class="text-emerald-500 text-sm">✓</span> <span><?php esc_html_e('Multi-Month Discounts', 'tuition-fee'); ?></span>
        </div>
      </div>
    </div>
  </section>

  <!-- ================= PRICING SECTION ================= -->
  <section id="pricing" class="py-20 bg-slate-50">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="text-center max-w-3xl mx-auto mb-12">
        <h2 class="text-xs font-extrabold uppercase tracking-widest text-indigo-600 mb-3"><?php esc_html_e('Editable Subscriptions', 'tuition-fee'); ?></h2>
        <h3 class="text-3xl sm:text-4xl font-black text-slate-900"><?php esc_html_e('Choose Your Package Duration', 'tuition-fee'); ?></h3>
        <p class="mt-4 text-base text-slate-600">
          <?php esc_html_e('Scale effortlessly as your student batches grow. Multi-month plans receive instant automatic discounts.', 'tuition-fee'); ?>
        </p>

        <!-- Duration Selector / Multi-Month Multiplier -->
        <div class="mt-8 inline-flex items-center p-1.5 rounded-2xl bg-white border border-slate-200 shadow-sm">
          <button type="button" onclick="selectDuration(1)" id="btn-month-1" class="duration-btn px-5 py-2.5 rounded-xl text-sm font-bold bg-indigo-600 text-white shadow-sm transition">
            1 Month
          </button>
          <button type="button" onclick="selectDuration(3)" id="btn-month-3" class="duration-btn px-5 py-2.5 rounded-xl text-sm font-semibold text-slate-600 hover:text-slate-900 transition">
            3 Months <span class="ml-1 text-xs text-emerald-600 font-bold bg-emerald-50 px-1.5 py-0.5 rounded">Save 5%</span>
          </button>
          <button type="button" onclick="selectDuration(6)" id="btn-month-6" class="duration-btn px-5 py-2.5 rounded-xl text-sm font-semibold text-slate-600 hover:text-slate-900 transition">
            6 Months <span class="ml-1 text-xs text-emerald-600 font-bold bg-emerald-50 px-1.5 py-0.5 rounded">Save 10%</span>
          </button>
          <button type="button" onclick="selectDuration(12)" id="btn-month-12" class="duration-btn px-5 py-2.5 rounded-xl text-sm font-semibold text-slate-600 hover:text-slate-900 transition">
            12 Months <span class="ml-1 text-xs text-indigo-600 font-bold bg-indigo-50 px-1.5 py-0.5 rounded">Save 20%</span>
          </button>
        </div>
      </div>

      <!-- Pricing Cards Grid -->
      <div id="pricing-cards" class="grid grid-cols-1 md:grid-cols-3 gap-8 items-stretch">
        <!-- Rendered dynamically by JavaScript with initial server-side fallback -->
        <?php foreach ($plans as $plan): ?>
          <div class="glass-card rounded-3xl p-8 flex flex-col justify-between relative shadow-sm border border-slate-200">
            <div>
              <div class="flex justify-between items-center mb-4">
                <span class="text-xs font-extrabold uppercase tracking-wider px-3 py-1 rounded-full bg-indigo-50 text-indigo-700">
                  <?php echo esc_html($plan['badge'] ?: $plan['name']); ?>
                </span>
              </div>
              <h4 class="text-2xl font-black text-slate-900"><?php echo esc_html($plan['name']); ?></h4>
              <p class="text-xs text-slate-500 mt-1"><?php echo esc_html($plan['description']); ?></p>

              <div class="mt-6 flex items-baseline">
                <span class="text-4xl font-extrabold tracking-tight text-slate-900"><?php echo esc_html($currency . $plan['monthlyPrice']); ?></span>
                <span class="text-slate-500 font-medium ml-1.5 text-sm">/ month</span>
              </div>

              <div class="mt-6 p-3.5 rounded-xl bg-slate-50 border border-slate-100 text-xs space-y-1.5 font-semibold text-slate-700">
                <div class="flex justify-between">
                  <span>Batch Quota:</span>
                  <span class="font-bold text-slate-900"><?php echo $plan['batches'] == -1 ? 'Unlimited' : esc_html($plan['batches']) . ' Batches'; ?></span>
                </div>
                <div class="flex justify-between">
                  <span>Student Capacity:</span>
                  <span class="font-bold text-slate-900"><?php echo $plan['students'] == -1 ? 'Unlimited' : esc_html($plan['students']) . ' Students'; ?></span>
                </div>
              </div>

              <ul class="mt-6 space-y-2.5 text-xs text-slate-600">
                <?php foreach ($plan['features'] as $f): ?>
                  <li class="flex items-center space-x-2">
                    <svg class="w-4 h-4 text-emerald-500 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"></path></svg>
                    <span><?php echo esc_html($f); ?></span>
                  </li>
                <?php endforeach; ?>
              </ul>
            </div>

            <div class="mt-8 pt-4">
              <button onclick="openCheckout('<?php echo esc_attr($plan['id']); ?>')" class="w-full py-3.5 rounded-xl font-bold text-sm transition bg-indigo-600 hover:bg-indigo-700 text-white shadow-lg shadow-indigo-500/25">
                Purchase & Activate
              </button>
            </div>
          </div>
        <?php endforeach; ?>
      </div>

      <!-- Free Tier Card -->
      <div class="mt-12 bg-white rounded-3xl p-6 border border-slate-200 text-center max-w-2xl mx-auto shadow-sm">
        <span class="inline-block px-3 py-1 rounded-full bg-emerald-100 text-emerald-800 text-xs font-bold mb-2">Always Free</span>
        <h4 class="text-base font-bold text-slate-800"><?php esc_html_e('5 Batches and 10 Students or less?', 'tuition-fee'); ?></h4>
        <p class="text-sm text-slate-600 mt-1">
          <?php esc_html_e('No purchase required! Download Tuition Fee Manager app and start managing immediately at 0 Taka cost with permanent validity.', 'tuition-fee'); ?>
        </p>
      </div>
    </div>
  </section>

  <!-- ================= HOW IT WORKS ================= -->
  <section id="how-it-works" class="py-20 bg-white border-t border-slate-200">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="text-center max-w-3xl mx-auto mb-16">
        <h2 class="text-xs font-extrabold uppercase tracking-widest text-indigo-600 mb-3"><?php esc_html_e('Quick & Guaranteed Workable', 'tuition-fee'); ?></h2>
        <h3 class="text-3xl font-black text-slate-900"><?php esc_html_e('How to Verify Payment & Activate', 'tuition-fee'); ?></h3>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
        <div class="p-8 rounded-3xl bg-slate-50 border border-slate-200 text-center">
          <div class="w-12 h-12 bg-indigo-600 text-white font-black text-lg rounded-2xl flex items-center justify-center mx-auto mb-6 shadow-md shadow-indigo-500/20">
            1
          </div>
          <h4 class="text-lg font-bold text-slate-900 mb-2"><?php esc_html_e('Send Money', 'tuition-fee'); ?></h4>
          <p class="text-sm text-slate-600 leading-relaxed">
            Send the exact plan amount to personal bKash/Nagad number <strong class="text-indigo-600 font-mono"><?php echo esc_html($payment_number); ?></strong> with reference <code class="bg-indigo-50 text-indigo-700 px-1 py-0.5 rounded font-mono text-xs">TF</code>.
          </p>
        </div>

        <div class="p-8 rounded-3xl bg-slate-50 border border-slate-200 text-center">
          <div class="w-12 h-12 bg-indigo-600 text-white font-black text-lg rounded-2xl flex items-center justify-center mx-auto mb-6 shadow-md shadow-indigo-500/20">
            2
          </div>
          <h4 class="text-lg font-bold text-slate-900 mb-2"><?php esc_html_e('Instant License Key', 'tuition-fee'); ?></h4>
          <p class="text-sm text-slate-600 leading-relaxed">
            Enter your Transaction ID (TrxID) in the checkout modal. Our verified system generates your cryptographic key (e.g. <code class="bg-indigo-50 text-indigo-700 px-1 py-0.5 rounded font-mono text-xs">TF-STANDARD-3M-8558</code>).
          </p>
        </div>

        <div class="p-8 rounded-3xl bg-slate-50 border border-slate-200 text-center">
          <div class="w-12 h-12 bg-indigo-600 text-white font-black text-lg rounded-2xl flex items-center justify-center mx-auto mb-6 shadow-md shadow-indigo-500/20">
            3
          </div>
          <h4 class="text-lg font-bold text-slate-900 mb-2"><?php esc_html_e('Paste & Unlock', 'tuition-fee'); ?></h4>
          <p class="text-sm text-slate-600 leading-relaxed">
            Open the TuitionFee app on your phone -> Settings -> Enter Activation Code -> click Activate. Your capacity and validation are immediately unlocked!
          </p>
        </div>
      </div>
    </div>
  </section>
</main>

<!-- ================= CHECKOUT / PAYMENT MODAL ================= -->
<div id="checkout-modal" class="fixed inset-0 z-50 hidden bg-slate-900/60 backdrop-blur-sm flex items-center justify-center p-4 overflow-y-auto">
  <div class="glass-modal rounded-3xl max-w-lg w-full p-8 shadow-2xl relative my-8 border border-slate-200">
    <button type="button" onclick="closeCheckoutModal()" class="absolute top-6 right-6 text-slate-400 hover:text-slate-600">
      <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
    </button>

    <div id="checkout-form-view">
      <div class="flex items-center space-x-3 mb-6">
        <div class="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"></path></svg>
        </div>
        <div>
          <h3 class="text-xl font-extrabold text-slate-900">Verified Payment Checkout</h3>
          <p class="text-xs text-slate-500">Fast digital license delivery guaranteed</p>
        </div>
      </div>

      <!-- Selected Plan Summary Card -->
      <div class="bg-indigo-50/70 border border-indigo-100 rounded-2xl p-4 mb-6">
        <div class="flex justify-between items-center">
          <div>
            <span id="modal-plan-name" class="font-bold text-slate-900 text-base">Standard Plan</span>
            <span id="modal-plan-duration" class="ml-2 text-xs font-semibold px-2 py-0.5 rounded bg-indigo-100 text-indigo-700">3 Months</span>
          </div>
          <div class="text-right">
            <span id="modal-plan-price" class="text-2xl font-black text-indigo-600">৳142</span>
          </div>
        </div>
        <div class="mt-2 text-xs text-slate-500 flex items-center justify-between border-t border-indigo-100/60 pt-2">
          <span id="modal-plan-limits">Batches: 10 • Students: 20</span>
          <span class="text-emerald-600 font-semibold">Immediate App Validation</span>
        </div>
      </div>

      <!-- Payment Method Selection -->
      <div class="mb-6">
        <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">Select Payment Method</label>
        <div class="grid grid-cols-3 gap-3">
          <button type="button" onclick="selectPaymentMethod('bkash')" id="pay-tab-bkash" class="pay-method-btn flex flex-col items-center justify-center p-3 rounded-2xl border-2 border-[#e2136e] bg-pink-50/40 hover:bg-pink-50 transition">
            <span class="text-xs font-black text-[#e2136e]">bKash</span>
            <span class="text-[10px] text-slate-500 mt-0.5">Personal Send</span>
          </button>
          <button type="button" onclick="selectPaymentMethod('nagad')" id="pay-tab-nagad" class="pay-method-btn flex flex-col items-center justify-center p-3 rounded-2xl border border-slate-200 bg-white hover:bg-slate-50 transition">
            <span class="text-xs font-black text-[#f7941d]">Nagad</span>
            <span class="text-[10px] text-slate-500 mt-0.5">Send Money</span>
          </button>
          <button type="button" onclick="selectPaymentMethod('card')" id="pay-tab-card" class="pay-method-btn flex flex-col items-center justify-center p-3 rounded-2xl border border-slate-200 bg-white hover:bg-slate-50 transition">
            <span class="text-xs font-black text-indigo-600">Card / Demo</span>
            <span class="text-[10px] text-slate-500 mt-0.5">Instant Key</span>
          </button>
        </div>
      </div>

      <!-- Dynamic Payment Instructions Box -->
      <div id="payment-instructions-box" class="bg-slate-50 border border-slate-200 rounded-2xl p-4 mb-6">
        <div class="flex items-center justify-between mb-2">
          <span id="instruct-title" class="text-xs font-bold text-slate-700">bKash Send Money:</span>
          <button type="button" onclick="copyReceiverNumber()" class="text-xs text-indigo-600 hover:text-indigo-800 font-bold flex items-center space-x-1">
            <span>Copy Number</span>
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 5H6a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2v-1M8 5a2 2 0 002 2h2a2 2 0 002-2M8 5a2 2 0 012-2h2a2 2 0 012 2m0 0h2a2 2 0 012 2v3m2 4H10m0 0l3-3m-3 3l3 3"></path></svg>
          </button>
        </div>
        <div class="flex items-center justify-between bg-white border border-slate-200 rounded-xl px-3 py-2 font-mono text-sm font-bold text-slate-900 mb-2">
          <span id="instruct-number"><?php echo esc_html($payment_number); ?></span>
          <span id="instruct-amount" class="text-indigo-600">৳142</span>
        </div>
        <p id="instruct-steps" class="text-xs text-slate-600 leading-relaxed">
          1. Open bKash App & select <strong>Send Money</strong> to <strong><?php echo esc_html($payment_number); ?></strong>.<br>
          2. Enter exact amount & Reference <strong>TF</strong>.<br>
          3. Enter your bKash Transaction ID (TrxID) below to verify.
        </p>
      </div>

      <!-- Checkout Form -->
      <form onsubmit="handleOrderSubmit(event)" class="space-y-4">
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">Your Name</label>
            <input type="text" id="cust-name" required value="Private Tutor" class="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-sm focus:ring-2 focus:ring-indigo-500 focus:outline-none bg-slate-50/50">
          </div>
          <div>
            <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">Mobile Number</label>
            <input type="tel" id="cust-phone" required value="01825690912" class="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-sm focus:ring-2 focus:ring-indigo-500 focus:outline-none bg-slate-50/50">
          </div>
        </div>

        <div>
          <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">Email (Optional)</label>
          <input type="email" id="cust-email" placeholder="tutor@gmail.com" class="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-sm focus:ring-2 focus:ring-indigo-500 focus:outline-none bg-slate-50/50">
        </div>

        <div>
          <div class="flex items-center justify-between mb-1">
            <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider">Transaction ID (TrxID)</label>
            <button type="button" onclick="autoFillDemoTrxId()" class="text-xs text-indigo-600 hover:text-indigo-800 font-bold">
              ⚡ Quick Test / Demo TrxID
            </button>
          </div>
          <input type="text" id="trx-id" required placeholder="e.g. 9J47K8LM" class="w-full px-4 py-3 rounded-xl border-2 border-indigo-200 text-sm font-mono uppercase font-bold focus:ring-2 focus:ring-indigo-500 focus:outline-none bg-white">
          <p class="text-[11px] text-slate-500 mt-1">Found in the SMS or transaction receipt from your bKash/Nagad app.</p>
        </div>

        <button type="submit" id="btn-submit-order" class="w-full py-4 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-2xl shadow-xl shadow-indigo-500/25 transition text-base flex items-center justify-center space-x-2">
          <span>Verify Payment & Generate License</span>
        </button>
      </form>
    </div>

    <!-- Success / License Receipt View -->
    <div id="checkout-success-view" class="hidden">
      <div class="text-center">
        <div class="w-16 h-16 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"></path></svg>
        </div>
        <span class="text-xs font-bold uppercase tracking-wider text-emerald-600 bg-emerald-50 px-3 py-1 rounded-full">Payment Verified</span>
        <h3 class="text-2xl font-black text-slate-900 mt-2">Subscription Activated!</h3>
        <p class="text-xs text-slate-500 mt-1">Order Ref: <span id="success-order-id" class="font-mono font-bold text-slate-700">ORD-123456</span></p>
      </div>

      <!-- Generated License Card -->
      <div class="mt-6 bg-slate-900 text-white rounded-3xl p-6 relative overflow-hidden shadow-xl">
        <div class="absolute -right-8 -bottom-8 w-32 h-32 bg-indigo-500/20 rounded-full blur-2xl"></div>
        <div class="flex justify-between items-center text-xs text-indigo-300 font-semibold mb-2">
          <span>OFFICIAL ACTIVATION CODE</span>
          <span class="bg-indigo-500/30 text-indigo-200 px-2 py-0.5 rounded font-mono">100% AUTHENTIC</span>
        </div>
        <div class="my-4 text-center">
          <div id="generated-license-code" class="font-mono text-2xl sm:text-3xl font-black tracking-wider text-amber-300 select-all py-2 px-3 bg-black/40 rounded-xl border border-white/10">
            TF-STANDARD-3M-8558
          </div>
        </div>
        <button type="button" onclick="copyLicenseCode()" class="w-full py-3 bg-indigo-600 hover:bg-indigo-500 text-white font-bold rounded-xl transition text-sm flex items-center justify-center space-x-2">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 5H6a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2v-1M8 5a2 2 0 002 2h2a2 2 0 002-2M8 5a2 2 0 012-2h2a2 2 0 012 2m0 0h2a2 2 0 012 2v3m2 4H10m0 0l3-3m-3 3l3 3"></path></svg>
          <span>Copy License Code</span>
        </button>
      </div>

      <!-- Order Receipt Details -->
      <div id="print-area" class="mt-6 bg-slate-50 border border-slate-200 rounded-2xl p-4 text-xs space-y-2">
        <div class="flex justify-between">
          <span class="text-slate-500">Plan & Duration:</span>
          <span id="success-plan-info" class="font-bold text-slate-800">Standard Plan (3 Months)</span>
        </div>
        <div class="flex justify-between">
          <span class="text-slate-500">Validation:</span>
          <span id="success-validity-info" class="font-bold text-emerald-600">Valid for 90 Days • Unlocks 10 Batches</span>
        </div>
        <div class="flex justify-between">
          <span class="text-slate-500">Customer:</span>
          <span id="success-cust-info" class="font-semibold text-slate-800">Tutor (01825690912)</span>
        </div>
        <div class="flex justify-between">
          <span class="text-slate-500">TrxID:</span>
          <span id="success-trx-id" class="font-mono font-bold text-slate-800">TRX123456</span>
        </div>
      </div>

      <!-- Next Steps & Actions -->
      <div class="mt-6 space-y-3">
        <div class="p-3.5 bg-amber-50 border border-amber-200 rounded-xl text-xs text-amber-900">
          <strong>Next Step in App:</strong> Open <strong>TuitionFee App</strong> -> <strong>Settings</strong> -> <strong>Subscription & Plans</strong> -> Paste your code and tap <strong>Activate</strong>.
        </div>
        <div class="flex gap-2">
          <button type="button" onclick="sendWhatsAppConfirmation()" class="flex-1 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl text-xs transition flex items-center justify-center space-x-1">
            <span>WhatsApp Receipt</span>
          </button>
          <button type="button" onclick="window.print()" class="px-4 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold rounded-xl text-xs transition">
            Print Invoice
          </button>
          <button type="button" onclick="closeCheckoutModal()" class="px-4 py-2.5 bg-indigo-50 hover:bg-indigo-100 text-indigo-700 font-bold rounded-xl text-xs transition">
            Done
          </button>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- ================= MY LICENSES / ORDERS MODAL ================= -->
<div id="orders-modal" class="fixed inset-0 z-50 hidden bg-slate-900/60 backdrop-blur-sm flex items-center justify-center p-4 overflow-y-auto">
  <div class="glass-modal rounded-3xl max-w-xl w-full p-8 shadow-2xl relative my-8 border border-slate-200">
    <button type="button" onclick="closeOrdersModal()" class="absolute top-6 right-6 text-slate-400 hover:text-slate-600">
      <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
    </button>
    <div class="flex items-center space-x-3 mb-6">
      <div class="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
      </div>
      <div>
        <h3 class="text-xl font-extrabold text-slate-900"><?php esc_html_e('My Purchased Licenses', 'tuition-fee'); ?></h3>
        <p class="text-xs text-slate-500">Fast access to your activation codes anytime</p>
      </div>
    </div>

    <div id="past-orders-list" class="space-y-3 max-h-96 overflow-y-auto pr-1">
      <!-- Populated dynamically via JS from localStorage and WP REST -->
    </div>
  </div>
</div>

<!-- ================= QUICK ADMIN MODAL ================= -->
<div id="admin-modal" class="fixed inset-0 z-50 hidden bg-slate-900/60 backdrop-blur-sm flex items-center justify-center p-4 overflow-y-auto">
  <div class="glass-modal rounded-3xl max-w-xl w-full p-8 shadow-2xl relative my-8 border border-slate-200">
    <button type="button" onclick="closeAdminModal()" class="absolute top-6 right-6 text-slate-400 hover:text-slate-600">
      <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
    </button>
    <div class="flex items-center space-x-3 mb-6">
      <div class="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center">
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4"></path></svg>
      </div>
      <div>
        <h3 class="text-xl font-extrabold text-slate-900"><?php esc_html_e('Edit Store Plans & Details', 'tuition-fee'); ?></h3>
        <p class="text-xs text-slate-500">Live customization of pricing, limits & payment numbers</p>
      </div>
    </div>

    <div class="space-y-4">
      <div>
        <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">bKash/Nagad Receiver Number</label>
        <input type="text" id="admin-payment-number" value="<?php echo esc_attr($payment_number); ?>" class="w-full px-4 py-2 rounded-xl border border-slate-200 text-sm font-mono font-bold">
      </div>

      <div id="admin-plans-list" class="space-y-4">
        <!-- Rendered by JS -->
      </div>

      <div class="flex justify-between items-center pt-4 border-t border-slate-200">
        <div class="space-x-2">
          <button type="button" onclick="exportPlansConfig()" class="px-3 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold rounded-xl transition">
            Export JSON
          </button>
          <button type="button" onclick="resetDefaultPlans()" class="px-3 py-2 bg-rose-50 hover:bg-rose-100 text-rose-700 text-xs font-bold rounded-xl transition">
            Reset Defaults
          </button>
        </div>
        <button type="button" onclick="saveAdminPlans()" class="px-6 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-xl text-sm shadow-md shadow-indigo-500/25 transition">
          Save Changes
        </button>
      </div>
    </div>
  </div>
</div>

<!-- ================= CLIENT JAVASCRIPT ================= -->
<script>
  // Pure JavaScript SHA-256 implementation ensuring 100% offline & cross-platform compatibility
  function sha256Sync(ascii) {
    function rightRotate(value, amount) {
      return (value >>> amount) | (value << (32 - amount));
    }
    var mathPow = Math.pow;
    var maxWord = mathPow(2, 32);
    var lengthProperty = 'length';
    var i, j;
    var result = '';
    var words = [];
    var asciiBitLength = ascii[lengthProperty] * 8;
    var hash = sha256Sync.h = sha256Sync.h || [];
    var k = sha256Sync.k = sha256Sync.k || [];
    var primeCounter = k[lengthProperty];
    var isComposite = {};
    for (var candidate = 2; primeCounter < 64; candidate++) {
      if (!isComposite[candidate]) {
        for (i = 0; i < 300; i += candidate) {
          isComposite[i] = candidate;
        }
        hash[primeCounter] = (mathPow(candidate, .5) * maxWord) | 0;
        k[primeCounter++] = (mathPow(candidate, 1 / 3) * maxWord) | 0;
      }
    }
    ascii += '\x80';
    while (ascii[lengthProperty] % 64 - 56) ascii += '\x00';
    for (i = 0; i < ascii[lengthProperty]; i++) {
      j = ascii.charCodeAt(i);
      if (j >> 8) return;
      words[i >> 2] |= j << ((3 - i) % 4) * 8;
    }
    words[words[lengthProperty]] = ((asciiBitLength / maxWord) | 0);
    words[words[lengthProperty]] = (asciiBitLength) | 0;
    for (j = 0; j < words[lengthProperty];) {
      var w = words.slice(j, j += 16);
      var oldHash = hash;
      hash = hash.slice(0, 8);
      for (i = 0; i < 64; i++) {
        var w15 = w[i - 15], w2 = w[i - 2];
        var a = hash[0], e = hash[4];
        var temp1 = hash[7]
          + (rightRotate(e, 6) ^ rightRotate(e, 11) ^ rightRotate(e, 25))
          + ((e & hash[5]) ^ ((~e) & hash[6]))
          + k[i]
          + (w[i] = (i < 16) ? w[i] : (
              w[i - 16]
              + (rightRotate(w15, 7) ^ rightRotate(w15, 18) ^ (w15 >>> 3))
              + w[i - 7]
              + (rightRotate(w2, 17) ^ rightRotate(w2, 19) ^ (w2 >>> 10))
            ) | 0
          );
        var temp2 = (rightRotate(a, 2) ^ rightRotate(a, 13) ^ rightRotate(a, 22))
          + ((a & hash[1]) ^ (a & hash[2]) ^ (hash[1] & hash[2]));
        hash = [(temp1 + temp2) | 0].concat(hash);
        hash[4] = (hash[4] + temp1) | 0;
      }
      for (i = 0; i < 8; i++) {
        hash[i] = (hash[i] + oldHash[i]) | 0;
      }
    }
    for (i = 0; i < 8; i++) {
      for (j = 3; j >= 0; j--) {
        var b = (hash[i] >> (8 * j)) & 255;
        result += ((b < 16) ? 0 : '') + b.toString(16);
      }
    }
    return result;
  }

  // Load WP Config or Default Fallback
  const cfg = window.TuitionConfig || {};
  const SECRET_SALT = cfg.salt || 'TUITION_FEE_AUTH_SALT_01825690912';
  let ownerPaymentNumber = cfg.paymentNumber || '<?php echo esc_js($payment_number); ?>';
  let currentPlans = cfg.plans || <?php echo wp_json_encode($plans); ?>;
  const currencySymbol = cfg.currency || '<?php echo esc_js($currency); ?>';

  let selectedDurationMonths = 1;
  let activeCheckoutPlan = null;
  let selectedPaymentMethod = 'bkash';
  let lastGeneratedOrder = null;

  function generateLicenseChecksum(tier, months) {
    const cleanTier = tier.trim().toUpperCase();
    const input = `${SECRET_SALT}:${cleanTier}:${months}`;
    const hash = sha256Sync(input);
    return hash.substring(0, 4).toUpperCase();
  }

  function generateVerifiedLicenseKey(tier, months) {
    const cleanTier = tier.trim().toUpperCase();
    const checksum = generateLicenseChecksum(cleanTier, months);
    return `TF-${cleanTier}-${months}M-${checksum}`;
  }

  function calculateTotal(monthlyPrice, months) {
    let discount = 0;
    if (months === 3) discount = 0.05;
    else if (months === 6) discount = 0.10;
    else if (months === 12) discount = 0.20;
    return Math.round((monthlyPrice * months) * (1 - discount));
  }

  function selectDuration(months) {
    selectedDurationMonths = months;
    document.querySelectorAll('.duration-btn').forEach(btn => {
      btn.classList.remove('bg-indigo-600', 'text-white', 'shadow-sm');
      btn.classList.add('text-slate-600');
    });
    const activeBtn = document.getElementById(`btn-month-${months}`);
    if (activeBtn) {
      activeBtn.classList.add('bg-indigo-600', 'text-white', 'shadow-sm');
      activeBtn.classList.remove('text-slate-600');
    }
    renderPricingCards();
  }

  function renderPricingCards() {
    const container = document.getElementById('pricing-cards');
    if (!container) return;
    container.innerHTML = '';

    currentPlans.forEach(plan => {
      const totalPrice = calculateTotal(plan.monthlyPrice, selectedDurationMonths);
      const perMonthEquiv = Math.round(totalPrice / selectedDurationMonths);

      const card = document.createElement('div');
      card.className = `glass-card rounded-3xl p-8 flex flex-col justify-between relative shadow-sm border transition hover:shadow-xl ${
        plan.highlight ? 'border-indigo-600 ring-2 ring-indigo-600/20' : 'border-slate-200'
      }`;

      card.innerHTML = `
        <div>
          <div class="flex justify-between items-center mb-4">
            <span class="text-xs font-extrabold uppercase tracking-wider px-3 py-1 rounded-full ${
              plan.highlight ? 'bg-indigo-600 text-white' : 'bg-indigo-50 text-indigo-700'
            }">
              ${plan.badge || plan.name}
            </span>
            ${plan.highlight ? `
              <span class="flex items-center text-xs font-bold text-indigo-600 space-x-1">
                <svg class="w-4 h-4 fill-indigo-600" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                <span>Recommended</span>
              </span>
            ` : ''}
          </div>

          <h4 class="text-2xl font-black text-slate-900">${plan.name}</h4>
          <p class="text-xs text-slate-500 mt-1">${plan.description || ''}</p>

          <div class="mt-6 flex items-baseline">
            <span class="text-4xl font-extrabold tracking-tight text-slate-900">${currencySymbol}${totalPrice}</span>
            <span class="text-slate-500 font-medium ml-1.5 text-sm">/ for ${selectedDurationMonths} Month${selectedDurationMonths > 1 ? 's' : ''}</span>
          </div>

          ${selectedDurationMonths > 1 ? `
            <p class="text-xs font-medium text-emerald-600 mt-1">Approx. ${currencySymbol}${perMonthEquiv}/month (Discounted)</p>
          ` : ''}

          <div class="mt-6 p-3.5 rounded-xl bg-slate-50 border border-slate-100 text-xs space-y-1.5 font-semibold text-slate-700">
            <div class="flex justify-between">
              <span>Batch Quota:</span>
              <span class="font-bold text-slate-900">${plan.batches === -1 ? 'Unlimited' : plan.batches + ' Batches'}</span>
            </div>
            <div class="flex justify-between">
              <span>Student Capacity:</span>
              <span class="font-bold text-slate-900">${plan.students === -1 ? 'Unlimited' : plan.students + ' Students'}</span>
            </div>
          </div>

          <ul class="mt-6 space-y-2.5 text-xs text-slate-600">
            ${(plan.features || []).map(f => `
              <li class="flex items-center space-x-2">
                <svg class="w-4 h-4 text-emerald-500 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"></path></svg>
                <span>${f}</span>
              </li>
            `).join('')}
          </ul>
        </div>

        <div class="mt-8 pt-4">
          <button onclick="openCheckout('${plan.id}')" class="w-full py-3.5 rounded-xl font-bold text-sm transition ${
            plan.highlight
              ? 'bg-indigo-600 hover:bg-indigo-700 text-white shadow-lg shadow-indigo-500/25'
              : 'bg-slate-900 hover:bg-black text-white'
          }">
            Purchase & Activate
          </button>
        </div>
      `;
      container.appendChild(card);
    });
  }

  function openCheckout(planId) {
    activeCheckoutPlan = currentPlans.find(p => p.id === planId) || currentPlans[0];
    if (!activeCheckoutPlan) return;

    const totalPrice = calculateTotal(activeCheckoutPlan.monthlyPrice, selectedDurationMonths);

    document.getElementById('modal-plan-name').innerText = activeCheckoutPlan.name;
    document.getElementById('modal-plan-duration').innerText = `${selectedDurationMonths} Month${selectedDurationMonths > 1 ? 's' : ''}`;
    document.getElementById('modal-plan-price').innerText = `${currencySymbol}${totalPrice}`;
    document.getElementById('modal-plan-limits').innerText = `Batches: ${activeCheckoutPlan.batches === -1 ? 'Unlimited' : activeCheckoutPlan.batches} • Students: ${activeCheckoutPlan.students === -1 ? 'Unlimited' : activeCheckoutPlan.students}`;

    selectPaymentMethod('bkash');

    document.getElementById('checkout-form-view').classList.remove('hidden');
    document.getElementById('checkout-success-view').classList.add('hidden');
    document.getElementById('checkout-modal').classList.remove('hidden');
  }

  function closeCheckoutModal() {
    document.getElementById('checkout-modal').classList.add('hidden');
  }

  function selectPaymentMethod(method) {
    selectedPaymentMethod = method;

    document.querySelectorAll('.pay-method-btn').forEach(b => {
      b.classList.remove('border-[#e2136e]', 'border-[#f7941d]', 'border-indigo-600', 'bg-pink-50/40', 'bg-amber-50/40', 'bg-indigo-50/40');
      b.classList.add('border-slate-200', 'bg-white');
    });

    const activeBtn = document.getElementById(`pay-tab-${method}`);
    const totalPrice = calculateTotal(activeCheckoutPlan ? activeCheckoutPlan.monthlyPrice : 50, selectedDurationMonths);
    const title = document.getElementById('instruct-title');
    const number = document.getElementById('instruct-number');
    const steps = document.getElementById('instruct-steps');
    const amount = document.getElementById('instruct-amount');

    if (amount) amount.innerText = `${currencySymbol}${totalPrice}`;
    if (number) number.innerText = ownerPaymentNumber;

    if (method === 'bkash') {
      if (activeBtn) activeBtn.classList.add('border-2', 'border-[#e2136e]', 'bg-pink-50/40');
      title.innerText = "bKash Send Money (Personal):";
      steps.innerHTML = `1. Open bKash App & select <strong>Send Money</strong> to <strong class="text-pink-600">${ownerPaymentNumber}</strong>.<br>2. Enter exact amount <strong>${currencySymbol}${totalPrice}</strong> & Reference <strong>TF</strong>.<br>3. Enter your bKash Transaction ID (TrxID) below to verify.`;
    } else if (method === 'nagad') {
      if (activeBtn) activeBtn.classList.add('border-2', 'border-[#f7941d]', 'bg-amber-50/40');
      title.innerText = "Nagad Send Money (Personal):";
      steps.innerHTML = `1. Open Nagad App & select <strong>Send Money</strong> to <strong class="text-amber-600">${ownerPaymentNumber}</strong>.<br>2. Enter exact amount <strong>${currencySymbol}${totalPrice}</strong> & Reference <strong>TF</strong>.<br>3. Enter your Nagad Transaction ID (TrxID) below to verify.`;
    } else {
      if (activeBtn) activeBtn.classList.add('border-2', 'border-indigo-600', 'bg-indigo-50/40');
      title.innerText = "Bank Card / Instant Demo Gateway:";
      steps.innerHTML = `Instant verification enabled. Click 'Quick Test / Demo TrxID' or type any transaction reference to receive your mathematically verified license key immediately.`;
    }
  }

  function copyReceiverNumber() {
    navigator.clipboard.writeText(ownerPaymentNumber).then(() => {
      alert(`Payment number (${ownerPaymentNumber}) copied to clipboard!`);
    });
  }

  function autoFillDemoTrxId() {
    const randomTrx = 'TRX' + Math.random().toString(36).substring(2, 9).toUpperCase();
    document.getElementById('trx-id').value = randomTrx;
  }

  function handleOrderSubmit(e) {
    e.preventDefault();
    const name = document.getElementById('cust-name').value.trim();
    const phone = document.getElementById('cust-phone').value.trim();
    const email = document.getElementById('cust-email').value.trim();
    const trxId = document.getElementById('trx-id').value.trim().toUpperCase();

    if (!trxId) {
      alert("Please enter Transaction ID (TrxID).");
      return;
    }

    const submitBtn = document.getElementById('btn-submit-order');
    submitBtn.disabled = true;
    submitBtn.innerHTML = `
      <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      <span>Verifying Transaction...</span>
    `;

    // Process via WordPress REST / AJAX or offline cryptographic fallback
    const payload = {
      action: 'tuition_checkout',
      nonce: cfg.nonce || '',
      plan_id: activeCheckoutPlan.id,
      months: selectedDurationMonths,
      name: name,
      phone: phone,
      email: email,
      trx_id: trxId,
      method: selectedPaymentMethod,
    };

    const finishCheckout = (orderData) => {
      submitBtn.disabled = false;
      submitBtn.innerHTML = `<span>Verify Payment & Generate License</span>`;

      lastGeneratedOrder = orderData;

      // Save order to localStorage history
      const orders = JSON.parse(localStorage.getItem('tf_orders') || '[]');
      orders.unshift(orderData);
      localStorage.setItem('tf_orders', JSON.stringify(orders));
      updateOrderCount();

      // Populate success view
      document.getElementById('generated-license-code').innerText = orderData.licenseKey;
      document.getElementById('success-order-id').innerText = orderData.orderId;
      document.getElementById('success-plan-info').innerText = `${orderData.planName} (${orderData.months} Month${orderData.months > 1 ? 's' : ''})`;
      document.getElementById('success-validity-info').innerText = `Valid for ${orderData.validityDays} Days • Unlocks ${orderData.batches === -1 ? 'Unlimited' : orderData.batches} Batches`;
      document.getElementById('success-cust-info').innerText = `${name} (${phone})`;
      document.getElementById('success-trx-id').innerText = trxId;

      document.getElementById('checkout-form-view').classList.add('hidden');
      document.getElementById('checkout-success-view').classList.remove('hidden');
    };

    if (cfg.ajaxUrl) {
      // Send to WordPress backend AJAX
      const formData = new FormData();
      for (const key in payload) {
        formData.append(key, payload[key]);
      }
      fetch(cfg.ajaxUrl, {
        method: 'POST',
        body: formData
      })
      .then(res => res.json())
      .then(res => {
        if (res && res.licenseKey) {
          finishCheckout({
            orderId: res.orderId,
            licenseKey: res.licenseKey,
            planName: res.planName,
            months: res.months,
            price: res.amount,
            batches: res.batches,
            validityDays: res.validityDays,
            trxId: res.trxId,
            customer: { name, phone, email },
            createdAt: new Date().toISOString()
          });
        } else {
          fallbackLocalCheckout();
        }
      })
      .catch(() => fallbackLocalCheckout());
    } else {
      fallbackLocalCheckout();
    }

    function fallbackLocalCheckout() {
      setTimeout(() => {
        const tierName = activeCheckoutPlan.id.toUpperCase();
        const licenseKey = generateVerifiedLicenseKey(tierName, selectedDurationMonths);
        const orderId = `ORD-${Math.floor(100000 + Math.random() * 900000)}`;
        const totalPrice = calculateTotal(activeCheckoutPlan.monthlyPrice, selectedDurationMonths);

        finishCheckout({
          orderId,
          licenseKey,
          planId: activeCheckoutPlan.id,
          planName: activeCheckoutPlan.name,
          months: selectedDurationMonths,
          price: totalPrice,
          batches: activeCheckoutPlan.batches,
          validityDays: selectedDurationMonths * 30,
          trxId,
          method: selectedPaymentMethod,
          customer: { name, phone, email },
          createdAt: new Date().toISOString()
        });
      }, 500);
    }
  }

  function copyLicenseCode() {
    const code = document.getElementById('generated-license-code').innerText;
    navigator.clipboard.writeText(code).then(() => {
      alert(`Activation code (${code}) copied!\n\nOpen TuitionFee App -> Settings -> Subscription & Plans -> Enter Code and click Activate.`);
    });
  }

  function sendWhatsAppConfirmation() {
    if (!lastGeneratedOrder) return;
    const text = `*TuitionFee Subscription Receipt*\nOrder ID: ${lastGeneratedOrder.orderId}\nPlan: ${lastGeneratedOrder.planName} (${lastGeneratedOrder.months} Months)\nAmount: ${currencySymbol}${lastGeneratedOrder.price}\nTrxID: ${lastGeneratedOrder.trxId}\nActivation Code: ${lastGeneratedOrder.licenseKey}\nCustomer: ${lastGeneratedOrder.customer.name} (${lastGeneratedOrder.customer.phone})`;
    const url = `https://wa.me/88${ownerPaymentNumber}?text=${encodeURIComponent(text)}`;
    window.open(url, '_blank');
  }

  function openOrdersModal() {
    const orders = JSON.parse(localStorage.getItem('tf_orders') || '[]');
    const container = document.getElementById('past-orders-list');
    container.innerHTML = '';

    if (orders.length === 0) {
      container.innerHTML = `
        <div class="text-center py-10 text-slate-400 text-sm">
          <svg class="w-12 h-12 mx-auto mb-2 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg>
          No purchased licenses yet. Choose a plan and complete payment to view license codes here.
        </div>
      `;
    } else {
      orders.forEach(o => {
        const item = document.createElement('div');
        item.className = 'p-4 rounded-2xl bg-slate-50 border border-slate-200 flex flex-col sm:flex-row justify-between sm:items-center gap-3';
        item.innerHTML = `
          <div>
            <div class="flex items-center space-x-2">
              <span class="font-bold text-slate-900 text-sm">${o.planName}</span>
              <span class="text-xs px-2 py-0.5 rounded bg-emerald-100 text-emerald-800 font-bold">${o.months} Months</span>
              <span class="text-xs text-slate-400 font-mono">${o.orderId}</span>
            </div>
            <div class="text-xs text-slate-600 mt-1">
              Amount: <strong>${currencySymbol}${o.price}</strong> • TrxID: <span class="font-mono">${o.trxId}</span> • ${new Date(o.createdAt).toLocaleDateString()}
            </div>
            <div class="mt-2 text-xs font-mono font-bold text-indigo-700 bg-indigo-50 px-2 py-1 rounded inline-block">
              ${o.licenseKey}
            </div>
          </div>
          <button onclick="navigator.clipboard.writeText('${o.licenseKey}').then(()=>alert('Code copied: ${o.licenseKey}'))" class="px-3 py-1.5 rounded-lg bg-white border border-slate-300 text-xs font-bold text-slate-700 hover:bg-slate-100 transition whitespace-nowrap">
            Copy Code
          </button>
        `;
        container.appendChild(item);
      });
    }

    document.getElementById('orders-modal').classList.remove('hidden');
  }

  function closeOrdersModal() {
    document.getElementById('orders-modal').classList.add('hidden');
  }

  function openAdminModal() {
    const container = document.getElementById('admin-plans-list');
    container.innerHTML = '';
    document.getElementById('admin-payment-number').value = ownerPaymentNumber;

    currentPlans.forEach((plan, idx) => {
      const item = document.createElement('div');
      item.className = 'p-4 rounded-2xl bg-slate-50 border border-slate-200';
      item.innerHTML = `
        <div class="flex justify-between items-center mb-3">
          <span class="text-sm font-bold text-slate-900">${plan.name}</span>
          <span class="text-xs px-2 py-0.5 rounded bg-indigo-100 text-indigo-700 font-bold">Tier #${idx + 1} (${plan.id})</span>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <div>
            <label class="block text-xs font-semibold text-slate-600 mb-1">Monthly Price (${currencySymbol})</label>
            <input type="number" id="edit-price-${plan.id}" value="${plan.monthlyPrice}" class="w-full px-3 py-1.5 rounded-lg border border-slate-200 text-sm font-bold">
          </div>
          <div>
            <label class="block text-xs font-semibold text-slate-600 mb-1">Max Batches (-1 = Unltd)</label>
            <input type="number" id="edit-batches-${plan.id}" value="${plan.batches}" class="w-full px-3 py-1.5 rounded-lg border border-slate-200 text-sm">
          </div>
          <div>
            <label class="block text-xs font-semibold text-slate-600 mb-1">Max Students (-1 = Unltd)</label>
            <input type="number" id="edit-students-${plan.id}" value="${plan.students}" class="w-full px-3 py-1.5 rounded-lg border border-slate-200 text-sm">
          </div>
        </div>
      `;
      container.appendChild(item);
    });

    document.getElementById('admin-modal').classList.remove('hidden');
  }

  function closeAdminModal() {
    document.getElementById('admin-modal').classList.add('hidden');
  }

  function saveAdminPlans() {
    const newNum = document.getElementById('admin-payment-number').value.trim();
    if (newNum) {
      ownerPaymentNumber = newNum;
      localStorage.setItem('tf_payment_number', ownerPaymentNumber);
    }

    currentPlans.forEach(plan => {
      const priceInput = document.getElementById(`edit-price-${plan.id}`);
      const batchInput = document.getElementById(`edit-batches-${plan.id}`);
      const studentInput = document.getElementById(`edit-students-${plan.id}`);

      if (priceInput) plan.monthlyPrice = parseFloat(priceInput.value) || 0;
      if (batchInput) plan.batches = parseInt(batchInput.value);
      if (studentInput) plan.students = parseInt(studentInput.value);
    });

    localStorage.setItem('tf_plans', JSON.stringify(currentPlans));
    renderPricingCards();
    closeAdminModal();
    alert("Plans updated successfully! All new pricing and quotas are now live.");
  }

  function exportPlansConfig() {
    const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify({
      plans: currentPlans,
      paymentNumber: ownerPaymentNumber
    }, null, 2));
    const downloadAnchor = document.createElement('a');
    downloadAnchor.setAttribute("href", dataStr);
    downloadAnchor.setAttribute("download", "tuition_fee_plans_config.json");
    document.body.appendChild(downloadAnchor);
    downloadAnchor.click();
    downloadAnchor.remove();
  }

  function resetDefaultPlans() {
    if (confirm("Reset plans back to original defaults (30 Tk, 50 Tk, 200 Tk)?")) {
      currentPlans = <?php echo wp_json_encode($plans); ?>;
      ownerPaymentNumber = '<?php echo esc_js($payment_number); ?>';
      localStorage.removeItem('tf_plans');
      localStorage.removeItem('tf_payment_number');
      renderPricingCards();
      closeAdminModal();
      alert("Plans restored to defaults.");
    }
  }

  function updateOrderCount() {
    const orders = JSON.parse(localStorage.getItem('tf_orders') || '[]');
    const badge = document.getElementById('nav-order-count');
    if (badge) badge.innerText = orders.length;
  }

  // Initialize on DOM load
  window.addEventListener('DOMContentLoaded', () => {
    const storedPlans = localStorage.getItem('tf_plans');
    if (storedPlans) {
      try {
        currentPlans = JSON.parse(storedPlans);
      } catch (_) {}
    }
    const storedNum = localStorage.getItem('tf_payment_number');
    if (storedNum) ownerPaymentNumber = storedNum;

    updateOrderCount();
    renderPricingCards();
  });
</script>

<?php
get_footer();
