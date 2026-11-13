<?php
/**
 * Header template for Tuition Fee Manager WordPress Theme
 *
 * @package TuitionFee
 * @version 1.2.0
 */

if (!defined('ABSPATH')) {
    exit;
}
?>
<!DOCTYPE html>
<html <?php language_attributes(); ?> class="scroll-smooth">
<head>
  <meta charset="<?php bloginfo('charset'); ?>">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <?php wp_head(); ?>
</head>
<body <?php body_class('bg-slate-50 text-slate-900 font-sans antialiased min-h-screen flex flex-col'); ?>>
<?php
if (function_exists('wp_body_open')) {
    wp_body_open();
}
?>

  <!-- ================= TOP NAVIGATION ================= -->
  <header class="sticky top-0 z-40 bg-white/95 backdrop-blur-md border-b border-slate-200 shadow-sm">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-20 flex items-center justify-between">
      <div class="flex items-center space-x-3">
        <a href="<?php echo esc_url(home_url('/')); ?>" class="flex items-center space-x-3 group">
          <div class="w-11 h-11 rounded-xl bg-gradient-to-tr from-indigo-600 to-indigo-500 flex items-center justify-center text-white shadow-md shadow-indigo-500/25 group-hover:scale-105 transition">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"></path>
            </svg>
          </div>
          <div>
            <span class="text-xl font-extrabold tracking-tight text-slate-900"><?php bloginfo('name'); ?></span>
            <span class="text-xs ml-1.5 px-2 py-0.5 rounded-full bg-indigo-50 text-indigo-700 font-bold border border-indigo-100">PRO STORE</span>
          </div>
        </a>
      </div>

      <nav class="hidden md:flex items-center space-x-8 text-sm font-semibold text-slate-600">
        <a href="#pricing" class="hover:text-indigo-600 transition"><?php esc_html_e('Subscription Plans', 'tuition-fee'); ?></a>
        <a href="#how-it-works" class="hover:text-indigo-600 transition"><?php esc_html_e('Payment Guide', 'tuition-fee'); ?></a>
        <a href="javascript:void(0)" onclick="openOrdersModal()" class="hover:text-indigo-600 transition flex items-center space-x-1.5">
          <svg class="w-4 h-4 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
          <span><?php esc_html_e('My Licenses', 'tuition-fee'); ?> (<span id="nav-order-count">0</span>)</span>
        </a>
      </nav>

      <div class="flex items-center space-x-3">
        <?php if (current_user_can('manage_options')) : ?>
          <a href="<?php echo esc_url(admin_url('edit.php?post_type=tuition_plan')); ?>" class="px-3.5 py-2 text-xs font-bold text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-xl transition flex items-center space-x-1.5 border border-slate-200">
            <svg class="w-4 h-4 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
            </svg>
            <span>WP Admin</span>
          </a>
        <?php else : ?>
          <button onclick="openAdminModal()" class="px-3 py-2 text-xs font-bold text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-xl transition flex items-center space-x-1.5 border border-slate-200">
            <svg class="w-4 h-4 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
            </svg>
            <span>Edit Plans</span>
          </button>
        <?php endif; ?>

        <a href="#pricing" class="px-5 py-2.5 text-sm font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-lg shadow-indigo-500/25 transition">
          <?php esc_html_e('Purchase Plans', 'tuition-fee'); ?>
        </a>
      </div>
    </div>
  </header>
