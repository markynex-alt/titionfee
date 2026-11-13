<?php
/**
 * Footer template for Tuition Fee Manager WordPress Theme
 *
 * @package TuitionFee
 * @version 1.2.0
 */

if (!defined('ABSPATH')) {
    exit;
}
?>

  <!-- ================= FOOTER ================= -->
  <footer class="mt-auto bg-white border-t border-slate-200 py-12">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex flex-col md:flex-row items-center justify-between gap-6">
        <div class="flex items-center space-x-3">
          <div class="w-9 h-9 rounded-xl bg-indigo-600 flex items-center justify-center text-white font-black text-sm">
            TF
          </div>
          <div>
            <div class="font-extrabold text-slate-900 text-sm"><?php bloginfo('name'); ?></div>
            <div class="text-xs text-slate-500">Official Mobile App Subscription & Verification Engine</div>
          </div>
        </div>

        <div class="flex items-center space-x-6 text-xs font-semibold text-slate-600">
          <a href="#pricing" class="hover:text-indigo-600 transition"><?php esc_html_e('Pricing', 'tuition-fee'); ?></a>
          <a href="#how-it-works" class="hover:text-indigo-600 transition"><?php esc_html_e('How it Works', 'tuition-fee'); ?></a>
          <a href="javascript:void(0)" onclick="openOrdersModal()" class="hover:text-indigo-600 transition"><?php esc_html_e('My Orders', 'tuition-fee'); ?></a>
          <span class="text-slate-300">•</span>
          <span class="text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded font-mono font-bold">100% Verified Offline SHA-256</span>
        </div>

        <div class="text-xs text-slate-400">
          &copy; <?php echo date('Y'); ?> <?php bloginfo('name'); ?>. <?php esc_html_e('All rights reserved.', 'tuition-fee'); ?>
        </div>
      </div>
    </div>
  </footer>

  <?php wp_footer(); ?>
</body>
</html>
