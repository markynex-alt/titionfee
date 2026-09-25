<?php
/**
 * Tuition Fee eCommerce Theme Functions & Definitions
 *
 * @package TuitionFee
 * @version 1.1.0
 */

if (!defined('ABSPATH')) {
    exit; // Exit if accessed directly.
}

// Register Custom Post Types for Plans & Orders
function tuition_fee_register_cpts() {
    register_post_type('tuition_plan', [
        'labels' => [
            'name' => __('Tuition Plans', 'tuition-fee'),
            'singular_name' => __('Tuition Plan', 'tuition-fee'),
            'add_new_item' => __('Add New Plan', 'tuition-fee'),
            'edit_item' => __('Edit Plan', 'tuition-fee'),
        ],
        'public' => true,
        'has_archive' => false,
        'show_in_rest' => true,
        'menu_icon' => 'dashicons-tickets-alt',
        'supports' => ['title', 'editor', 'custom-fields'],
    ]);

    register_post_type('tuition_order', [
        'labels' => [
            'name' => __('Tuition Orders', 'tuition-fee'),
            'singular_name' => __('Tuition Order', 'tuition-fee'),
        ],
        'public' => false,
        'show_ui' => true,
        'menu_icon' => 'dashicons-cart',
        'supports' => ['title', 'custom-fields'],
    ]);
}
add_action('init', 'tuition_fee_register_cpts');

// Seed default plans if not already created
function tuition_fee_setup_default_plans() {
    if (get_option('tuition_fee_plans_seeded')) return;

    $plans = [
        [
            'title' => 'Starter Plan',
            'price' => 30,
            'batches' => 5,
            'students' => 10,
            'slug' => 'starter',
            'desc' => '5 batches & 10 students for 30 Taka/month',
        ],
        [
            'title' => 'Standard Plan',
            'price' => 50,
            'batches' => 10,
            'students' => 20,
            'slug' => 'standard',
            'desc' => '10 batches & 20 students for 50 Taka/month',
        ],
        [
            'title' => 'Unlimited Pro',
            'price' => 200,
            'batches' => -1,
            'students' => -1,
            'slug' => 'unlimited',
            'desc' => 'Unlimited batches and students for 200 Taka/month',
        ],
    ];

    foreach ($plans as $p) {
        $post_id = wp_insert_post([
            'post_title' => $p['title'],
            'post_name' => $p['slug'],
            'post_status' => 'publish',
            'post_type' => 'tuition_plan',
        ]);
        if ($post_id && !is_wp_error($post_id)) {
            update_post_meta($post_id, '_plan_price', $p['price']);
            update_post_meta($post_id, '_plan_batches', $p['batches']);
            update_post_meta($post_id, '_plan_students', $p['students']);
            update_post_meta($post_id, '_plan_desc', $p['desc']);
        }
    }

    update_option('tuition_fee_plans_seeded', true);
}
add_action('init', 'tuition_fee_setup_default_plans');

// REST API for Plans & Orders
add_action('rest_api_init', function () {
    register_rest_route('tuition/v1', '/plans', [
        'methods' => 'GET',
        'callback' => 'tuition_fee_api_get_plans',
        'permission_callback' => '__return_true',
    ]);

    register_rest_route('tuition/v1', '/checkout', [
        'methods' => 'POST',
        'callback' => 'tuition_fee_api_checkout',
        'permission_callback' => '__return_true',
    ]);
});

function tuition_fee_api_get_plans() {
    $posts = get_posts([
        'post_type' => 'tuition_plan',
        'numberposts' => -1,
        'post_status' => 'publish',
    ]);

    $data = [];
    foreach ($posts as $p) {
        $data[] = [
            'id' => $p->post_name,
            'name' => $p->post_title,
            'monthlyPrice' => (float) get_post_meta($p->ID, '_plan_price', true),
            'batches' => (int) get_post_meta($p->ID, '_plan_batches', true),
            'students' => (int) get_post_meta($p->ID, '_plan_students', true),
            'description' => get_post_meta($p->ID, '_plan_desc', true),
        ];
    }
    return rest_ensure_response($data);
}

function tuition_fee_api_checkout($request) {
    $params = $request->get_json_params();
    $plan_id = sanitize_text_field($params['plan_id'] ?? 'starter');
    $months = max(1, (int) ($params['months'] ?? 1));
    $name = sanitize_text_field($params['name'] ?? 'Tutor');
    $phone = sanitize_text_field($params['phone'] ?? '');
    $email = sanitize_email($params['email'] ?? '');

    $tier_code = strtoupper($plan_id);
    $hash = strtoupper(substr(md5(uniqid(rand(), true)), 0, 4));
    $license_key = "TF-{$tier_code}-{$months}M-{$hash}";

    $order_id = wp_insert_post([
        'post_title' => "Order {$license_key} - {$name}",
        'post_type' => 'tuition_order',
        'post_status' => 'publish',
    ]);

    if ($order_id && !is_wp_error($order_id)) {
        update_post_meta($order_id, '_license_key', $license_key);
        update_post_meta($order_id, '_plan_id', $plan_id);
        update_post_meta($order_id, '_months', $months);
        update_post_meta($order_id, '_customer_name', $name);
        update_post_meta($order_id, '_customer_phone', $phone);
        update_post_meta($order_id, '_customer_email', $email);
    }

    return rest_ensure_response([
        'success' => true,
        'licenseKey' => $license_key,
        'orderId' => $order_id,
        'months' => $months,
    ]);
}
