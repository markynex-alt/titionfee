<?php
/**
 * Tuition Fee Manager WordPress Theme Functions
 *
 * @package TuitionFee
 * @version 1.2.0
 */

if (!defined('ABSPATH')) {
    exit; // Exit if accessed directly.
}

define('TUITION_THEME_VERSION', '1.2.0');
define('TUITION_DEFAULT_SALT', 'TUITION_FEE_AUTH_SALT_01825690912');
define('TUITION_DEFAULT_PAYMENT_NUMBER', '01825690912');

/**
 * Theme Setup
 */
function tuition_fee_theme_setup() {
    add_theme_support('title-tag');
    add_theme_support('post-thumbnails');
    add_theme_support('responsive-embeds');
    add_theme_support('html5', [
        'search-form',
        'comment-form',
        'comment-list',
        'gallery',
        'caption',
        'style',
        'script'
    ]);
    add_theme_support('custom-logo', [
        'height'      => 80,
        'width'       => 240,
        'flex-width'  => true,
        'flex-height' => true,
    ]);

    register_nav_menus([
        'primary' => __('Primary Menu', 'tuition-fee'),
        'footer'  => __('Footer Menu', 'tuition-fee'),
    ]);
}
add_action('after_setup_theme', 'tuition_fee_theme_setup');

/**
 * Enqueue Styles and Scripts
 */
function tuition_fee_enqueue_scripts() {
    // Google Fonts
    wp_enqueue_style(
        'tuition-google-fonts',
        'https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800;900&display=swap',
        [],
        null
    );

    // Main Theme Stylesheet
    wp_enqueue_style(
        'tuition-style',
        get_stylesheet_uri(),
        [],
        TUITION_THEME_VERSION
    );

    // Tailwind CSS CDN
    wp_enqueue_script(
        'tuition-tailwind',
        'https://cdn.tailwindcss.com',
        [],
        null,
        false
    );

    // Pass dynamic configuration to front-end
    $plans_data = tuition_fee_get_plans_data();
    $config_data = [
        'ajaxUrl'       => admin_url('admin-ajax.php'),
        'restUrl'       => rest_url('tuition/v1/checkout'),
        'nonce'         => wp_create_nonce('tuition_fee_checkout_nonce'),
        'paymentNumber' => get_option('tuition_payment_number', TUITION_DEFAULT_PAYMENT_NUMBER),
        'salt'          => get_option('tuition_secret_salt', TUITION_DEFAULT_SALT),
        'currency'      => get_option('tuition_currency_symbol', '৳'),
        'plans'         => $plans_data,
        'discounts'     => [
            1  => 0.00,
            3  => floatval(get_option('tuition_discount_3m', 0.05)),
            6  => floatval(get_option('tuition_discount_6m', 0.10)),
            12 => floatval(get_option('tuition_discount_12m', 0.20)),
        ],
    ];

    wp_add_inline_script(
        'tuition-tailwind',
        'window.TuitionConfig = ' . wp_json_encode($config_data) . ';',
        'after'
    );
}
add_action('wp_enqueue_scripts', 'tuition_fee_enqueue_scripts');

/**
 * Register Custom Post Types: Plans & Orders
 */
function tuition_fee_register_cpts() {
    // Tuition Plans Post Type
    register_post_type('tuition_plan', [
        'labels' => [
            'name'               => __('Tuition Plans', 'tuition-fee'),
            'singular_name'      => __('Tuition Plan', 'tuition-fee'),
            'add_new'            => __('Add New Plan', 'tuition-fee'),
            'add_new_item'       => __('Add New Tuition Plan', 'tuition-fee'),
            'edit_item'          => __('Edit Tuition Plan', 'tuition-fee'),
            'new_item'           => __('New Plan', 'tuition-fee'),
            'view_item'          => __('View Plan', 'tuition-fee'),
            'search_items'       => __('Search Plans', 'tuition-fee'),
            'not_found'          => __('No plans found', 'tuition-fee'),
        ],
        'public'             => true,
        'has_archive'        => false,
        'show_in_rest'       => true,
        'menu_icon'          => 'dashicons-tickets-alt',
        'supports'           => ['title', 'editor'],
        'menu_position'      => 25,
    ]);

    // Tuition Orders Post Type
    register_post_type('tuition_order', [
        'labels' => [
            'name'               => __('Tuition Orders', 'tuition-fee'),
            'singular_name'      => __('Tuition Order', 'tuition-fee'),
            'all_items'          => __('All Orders & Licenses', 'tuition-fee'),
            'view_item'          => __('View Order', 'tuition-fee'),
            'search_items'       => __('Search Orders or TrxIDs', 'tuition-fee'),
            'not_found'          => __('No orders found', 'tuition-fee'),
        ],
        'public'             => false,
        'show_ui'            => true,
        'show_in_menu'       => 'edit.php?post_type=tuition_plan',
        'menu_icon'          => 'dashicons-cart',
        'supports'           => ['title'],
        'capability_type'    => 'post',
        'capabilities'       => [
            'create_posts' => 'do_not_allow',
        ],
        'map_meta_cap'       => true,
    ]);
}
add_action('init', 'tuition_fee_register_cpts');

/**
 * Meta Boxes for Tuition Plans
 */
function tuition_fee_add_plan_meta_boxes() {
    add_meta_box(
        'tuition_plan_details',
        __('Plan Configuration & Limits', 'tuition-fee'),
        'tuition_fee_render_plan_meta_box',
        'tuition_plan',
        'normal',
        'high'
    );
}
add_action('add_meta_boxes', 'tuition_fee_add_plan_meta_boxes');

function tuition_fee_render_plan_meta_box($post) {
    wp_nonce_field('tuition_plan_meta_nonce', 'tuition_plan_meta_nonce_field');

    $price = get_post_meta($post->ID, '_plan_price', true);
    $batches = get_post_meta($post->ID, '_plan_batches', true);
    $students = get_post_meta($post->ID, '_plan_students', true);
    $badge = get_post_meta($post->ID, '_plan_badge', true);
    $highlight = get_post_meta($post->ID, '_plan_highlight', true);
    $features = get_post_meta($post->ID, '_plan_features', true);

    if ($price === '') $price = '50';
    if ($batches === '') $batches = '10';
    if ($students === '') $students = '20';
    ?>
    <table class="form-table">
        <tr>
            <th scope="row"><label for="plan_price"><?php _e('Monthly Price (৳ Taka)', 'tuition-fee'); ?></label></th>
            <td>
                <input type="number" step="1" min="0" name="plan_price" id="plan_price" value="<?php echo esc_attr($price); ?>" class="regular-text" style="max-width:140px;" required />
                <p class="description"><?php _e('Base price for 1 month subscription (e.g. 30, 50, 200).', 'tuition-fee'); ?></p>
            </td>
        </tr>
        <tr>
            <th scope="row"><label for="plan_batches"><?php _e('Batch Quota', 'tuition-fee'); ?></label></th>
            <td>
                <input type="number" step="1" name="plan_batches" id="plan_batches" value="<?php echo esc_attr($batches); ?>" class="regular-text" style="max-width:140px;" required />
                <p class="description"><?php _e('Maximum number of batches allowed. Enter <strong>-1</strong> for Unlimited.', 'tuition-fee'); ?></p>
            </td>
        </tr>
        <tr>
            <th scope="row"><label for="plan_students"><?php _e('Student Capacity', 'tuition-fee'); ?></label></th>
            <td>
                <input type="number" step="1" name="plan_students" id="plan_students" value="<?php echo esc_attr($students); ?>" class="regular-text" style="max-width:140px;" required />
                <p class="description"><?php _e('Maximum number of students allowed. Enter <strong>-1</strong> for Unlimited.', 'tuition-fee'); ?></p>
            </td>
        </tr>
        <tr>
            <th scope="row"><label for="plan_badge"><?php _e('Badge Text', 'tuition-fee'); ?></label></th>
            <td>
                <input type="text" name="plan_badge" id="plan_badge" value="<?php echo esc_attr($badge); ?>" class="regular-text" placeholder="e.g. Most Popular, Best Value, Basic Tier" />
            </td>
        </tr>
        <tr>
            <th scope="row"><label for="plan_highlight"><?php _e('Featured / Highlight', 'tuition-fee'); ?></label></th>
            <td>
                <label>
                    <input type="checkbox" name="plan_highlight" id="plan_highlight" value="1" <?php checked($highlight, '1'); ?> />
                    <?php _e('Highlight this plan card on the frontend store', 'tuition-fee'); ?>
                </label>
            </td>
        </tr>
        <tr>
            <th scope="row"><label for="plan_features"><?php _e('Features List', 'tuition-fee'); ?></label></th>
            <td>
                <textarea name="plan_features" id="plan_features" rows="4" class="large-text" placeholder="Enter one feature per line..."><?php echo esc_textarea($features); ?></textarea>
                <p class="description"><?php _e('Enter each bullet point feature on a new line.', 'tuition-fee'); ?></p>
            </td>
        </tr>
    </table>
    <?php
}

function tuition_fee_save_plan_meta($post_id) {
    if (!isset($_POST['tuition_plan_meta_nonce_field']) || !wp_verify_nonce($_POST['tuition_plan_meta_nonce_field'], 'tuition_plan_meta_nonce')) {
        return;
    }
    if (defined('DOING_AUTOSAVE') && DOING_AUTOSAVE) return;
    if (!current_user_can('edit_post', $post_id)) return;

    if (isset($_POST['plan_price'])) {
        update_post_meta($post_id, '_plan_price', floatval($_POST['plan_price']));
    }
    if (isset($_POST['plan_batches'])) {
        update_post_meta($post_id, '_plan_batches', intval($_POST['plan_batches']));
    }
    if (isset($_POST['plan_students'])) {
        update_post_meta($post_id, '_plan_students', intval($_POST['plan_students']));
    }
    if (isset($_POST['plan_badge'])) {
        update_post_meta($post_id, '_plan_badge', sanitize_text_field($_POST['plan_badge']));
    }
    $highlight = isset($_POST['plan_highlight']) ? '1' : '0';
    update_post_meta($post_id, '_plan_highlight', $highlight);

    if (isset($_POST['plan_features'])) {
        update_post_meta($post_id, '_plan_features', sanitize_textarea_field($_POST['plan_features']));
    }
}
add_action('save_post_tuition_plan', 'tuition_fee_save_plan_meta');

/**
 * Meta Box for Orders Display
 */
function tuition_fee_add_order_meta_boxes() {
    add_meta_box(
        'tuition_order_details',
        __('Order & Cryptographic License Details', 'tuition-fee'),
        'tuition_fee_render_order_meta_box',
        'tuition_order',
        'normal',
        'high'
    );
}
add_action('add_meta_boxes', 'tuition_fee_add_order_meta_boxes');

function tuition_fee_render_order_meta_box($post) {
    $license_key = get_post_meta($post->ID, '_license_key', true);
    $plan_id = get_post_meta($post->ID, '_plan_id', true);
    $plan_name = get_post_meta($post->ID, '_plan_name', true);
    $months = get_post_meta($post->ID, '_months', true);
    $amount = get_post_meta($post->ID, '_amount', true);
    $customer_name = get_post_meta($post->ID, '_customer_name', true);
    $customer_phone = get_post_meta($post->ID, '_customer_phone', true);
    $customer_email = get_post_meta($post->ID, '_customer_email', true);
    $payment_method = get_post_meta($post->ID, '_payment_method', true);
    $trx_id = get_post_meta($post->ID, '_trx_id', true);
    $created_at = get_post_meta($post->ID, '_created_at', true);
    ?>
    <div style="background:#f8fafc; border:1px solid #e2e8f0; border-radius:8px; padding:16px; margin-bottom:16px;">
        <h3 style="margin-top:0; color:#4f46e5; font-size:16px;">
            <?php _e('Generated Mobile App Activation Code', 'tuition-fee'); ?>
        </h3>
        <div style="display:flex; align-items:center; gap:12px;">
            <code style="font-size:20px; font-weight:800; color:#1e1b4b; background:#e0e7ff; padding:8px 16px; border-radius:6px; letter-spacing:1px;">
                <?php echo esc_html($license_key); ?>
            </code>
            <button type="button" class="button" onclick="navigator.clipboard.writeText('<?php echo esc_js($license_key); ?>').then(()=>alert('Activation code copied!'));">
                <?php _e('Copy Code', 'tuition-fee'); ?>
            </button>
        </div>
        <p class="description" style="margin-top:8px;">
            <?php _e('User enters this key in TuitionFee App > Settings > Subscription & Plans to activate their subscription.', 'tuition-fee'); ?>
        </p>
    </div>

    <table class="form-table">
        <tr>
            <th><?php _e('Plan & Validity', 'tuition-fee'); ?></th>
            <td><strong><?php echo esc_html($plan_name ?: strtoupper($plan_id)); ?></strong> (<?php echo esc_html($months); ?> Month<?php echo $months > 1 ? 's' : ''; ?>)</td>
        </tr>
        <tr>
            <th><?php _e('Amount Paid', 'tuition-fee'); ?></th>
            <td><strong>৳<?php echo esc_html($amount); ?></strong></td>
        </tr>
        <tr>
            <th><?php _e('Payment Method & TrxID', 'tuition-fee'); ?></th>
            <td>
                <span class="badge" style="background:#fbcfe8; color:#9d174d; padding:2px 8px; border-radius:4px; font-weight:bold; text-transform:uppercase;">
                    <?php echo esc_html($payment_method ?: 'bKash'); ?>
                </span>
                <span style="font-family:monospace; margin-left:8px; font-weight:bold;">
                    TrxID: <?php echo esc_html($trx_id); ?>
                </span>
            </td>
        </tr>
        <tr>
            <th><?php _e('Customer Name & Contact', 'tuition-fee'); ?></th>
            <td>
                <?php echo esc_html($customer_name); ?><br>
                <a href="tel:<?php echo esc_attr($customer_phone); ?>"><?php echo esc_html($customer_phone); ?></a>
                <?php if ($customer_email): ?> • <a href="mailto:<?php echo esc_attr($customer_email); ?>"><?php echo esc_html($customer_email); ?></a><?php endif; ?>
            </td>
        </tr>
        <tr>
            <th><?php _e('Purchase Date', 'tuition-fee'); ?></th>
            <td><?php echo esc_html($created_at ?: $post->post_date); ?></td>
        </tr>
    </table>
    <?php
}

/**
 * Custom Columns for Tuition Plans in WP Admin
 */
function tuition_fee_plan_columns($columns) {
    return [
        'cb'        => '<input type="checkbox" />',
        'title'     => __('Plan Title', 'tuition-fee'),
        'price'     => __('Monthly Price', 'tuition-fee'),
        'batches'   => __('Batches Quota', 'tuition-fee'),
        'students'  => __('Student Limit', 'tuition-fee'),
        'badge'     => __('Badge / Featured', 'tuition-fee'),
        'date'      => __('Date', 'tuition-fee'),
    ];
}
add_filter('manage_tuition_plan_posts_columns', 'tuition_fee_plan_columns');

function tuition_fee_plan_custom_columns($column, $post_id) {
    switch ($column) {
        case 'price':
            $price = get_post_meta($post_id, '_plan_price', true);
            echo '<strong>৳' . esc_html($price ?: '0') . '</strong>/mo';
            break;
        case 'batches':
            $batches = get_post_meta($post_id, '_plan_batches', true);
            echo $batches == -1 ? '<span style="color:#059669; font-weight:bold;">Unlimited</span>' : esc_html($batches) . ' Batches';
            break;
        case 'students':
            $students = get_post_meta($post_id, '_plan_students', true);
            echo $students == -1 ? '<span style="color:#059669; font-weight:bold;">Unlimited</span>' : esc_html($students) . ' Students';
            break;
        case 'badge':
            $badge = get_post_meta($post_id, '_plan_badge', true);
            $hl = get_post_meta($post_id, '_plan_highlight', true);
            if ($badge) {
                echo '<span style="background:#e0e7ff; color:#4338ca; padding:2px 8px; border-radius:12px; font-size:11px; font-weight:bold;">' . esc_html($badge) . '</span> ';
            }
            if ($hl == '1') {
                echo '<span style="background:#fef3c7; color:#b45309; padding:2px 8px; border-radius:12px; font-size:11px; font-weight:bold;">★ Highlighted</span>';
            }
            break;
    }
}
add_action('manage_tuition_plan_posts_custom_column', 'tuition_fee_plan_custom_columns', 10, 2);

/**
 * Custom Columns for Tuition Orders in WP Admin
 */
function tuition_fee_order_columns($columns) {
    return [
        'cb'          => '<input type="checkbox" />',
        'title'       => __('Order & Customer', 'tuition-fee'),
        'license_key' => __('License Key', 'tuition-fee'),
        'plan_info'   => __('Plan / Duration', 'tuition-fee'),
        'amount'      => __('Amount', 'tuition-fee'),
        'trx_id'      => __('TrxID & Method', 'tuition-fee'),
        'date'        => __('Date', 'tuition-fee'),
    ];
}
add_filter('manage_tuition_order_posts_columns', 'tuition_fee_order_columns');

function tuition_fee_order_custom_columns($column, $post_id) {
    switch ($column) {
        case 'license_key':
            $key = get_post_meta($post_id, '_license_key', true);
            echo '<code style="background:#e0e7ff; color:#3730a3; padding:3px 6px; border-radius:4px; font-weight:bold;">' . esc_html($key) . '</code>';
            break;
        case 'plan_info':
            $plan = get_post_meta($post_id, '_plan_name', true);
            $months = get_post_meta($post_id, '_months', true);
            echo '<strong>' . esc_html($plan) . '</strong> (' . esc_html($months) . 'M)';
            break;
        case 'amount':
            $amount = get_post_meta($post_id, '_amount', true);
            echo '<strong>৳' . esc_html($amount) . '</strong>';
            break;
        case 'trx_id':
            $trx = get_post_meta($post_id, '_trx_id', true);
            $method = get_post_meta($post_id, '_payment_method', true);
            echo '<span style="text-transform:uppercase; font-size:11px; font-weight:bold; color:#be185d;">' . esc_html($method) . '</span><br>';
            echo '<span style="font-family:monospace; font-size:11px;">' . esc_html($trx) . '</span>';
            break;
    }
}
add_action('manage_tuition_order_posts_custom_column', 'tuition_fee_order_custom_columns', 10, 2);

/**
 * Seed Default Plans on Initial Activation
 */
function tuition_fee_seed_default_plans() {
    $existing = get_posts([
        'post_type'      => 'tuition_plan',
        'posts_per_page' => 1,
        'post_status'    => 'any',
    ]);

    if (!empty($existing)) {
        return; // Already initialized
    }

    $default_plans = [
        [
            'slug'        => 'starter',
            'title'       => 'Starter Plan',
            'price'       => 30,
            'batches'     => 5,
            'students'    => 10,
            'badge'       => 'Basic Tier',
            'highlight'   => '0',
            'features'    => "5 Batches included\n10 Students capacity\nFast offline ledger calculation\nFirebase cloud backup",
            'description' => 'Ideal for private tutors with up to 5 batches and 10 students.',
        ],
        [
            'slug'        => 'standard',
            'title'       => 'Standard Plan',
            'price'       => 50,
            'batches'     => 10,
            'students'    => 20,
            'badge'       => 'Most Popular',
            'highlight'   => '1',
            'features'    => "Up to 10 Batches\nUp to 20 Students\nPriority multi-month sync\nInstant ledger search & reports",
            'description' => 'Popular choice for full-time tutors and growing tuition batches.',
        ],
        [
            'slug'        => 'unlimited',
            'title'       => 'Unlimited Pro',
            'price'       => 200,
            'batches'     => -1,
            'students'    => -1,
            'badge'       => 'Best Value',
            'highlight'   => '0',
            'features'    => "Unlimited Batches\nUnlimited Students\nFull cloud synchronization\nPriority dedicated support",
            'description' => 'No limits! Perfect for large coaching centers and academic academies.',
        ],
    ];

    foreach ($default_plans as $p) {
        $post_id = wp_insert_post([
            'post_name'    => $p['slug'],
            'post_title'   => $p['title'],
            'post_content' => $p['description'],
            'post_status'  => 'publish',
            'post_type'    => 'tuition_plan',
        ]);

        if ($post_id && !is_wp_error($post_id)) {
            update_post_meta($post_id, '_plan_price', $p['price']);
            update_post_meta($post_id, '_plan_batches', $p['batches']);
            update_post_meta($post_id, '_plan_students', $p['students']);
            update_post_meta($post_id, '_plan_badge', $p['badge']);
            update_post_meta($post_id, '_plan_highlight', $p['highlight']);
            update_post_meta($post_id, '_plan_features', $p['features']);
        }
    }
}
add_action('init', 'tuition_fee_seed_default_plans');

/**
 * Fetch Clean Plans Array
 */
function tuition_fee_get_plans_data() {
    $posts = get_posts([
        'post_type'      => 'tuition_plan',
        'posts_per_page' => -1,
        'post_status'    => 'publish',
        'orderby'        => 'menu_order',
        'order'          => 'ASC',
    ]);

    if (empty($posts)) {
        return [
            [
                'id'           => 'starter',
                'name'         => 'Starter Plan',
                'badge'        => 'Basic Tier',
                'monthlyPrice' => 30,
                'batches'      => 5,
                'students'     => 10,
                'description'  => 'Ideal for private tutors with up to 5 batches and 10 students.',
                'features'     => ['5 Batches included', '10 Students capacity', 'Fast offline ledger calculation', 'Firebase cloud backup'],
                'highlight'    => false,
            ],
            [
                'id'           => 'standard',
                'name'         => 'Standard Plan',
                'badge'        => 'Most Popular',
                'monthlyPrice' => 50,
                'batches'      => 10,
                'students'     => 20,
                'description'  => 'Popular choice for full-time tutors and growing tuition batches.',
                'features'     => ['Up to 10 Batches', 'Up to 20 Students', 'Priority multi-month sync', 'Instant ledger search & reports'],
                'highlight'    => true,
            ],
            [
                'id'           => 'unlimited',
                'name'         => 'Unlimited Pro',
                'badge'        => 'Best Value',
                'monthlyPrice' => 200,
                'batches'      => -1,
                'students'     => -1,
                'description'  => 'No limits! Perfect for large coaching centers and academic academies.',
                'features'     => ['Unlimited Batches', 'Unlimited Students', 'Full cloud synchronization', 'Priority dedicated support'],
                'highlight'    => false,
            ],
        ];
    }

    $data = [];
    foreach ($posts as $p) {
        $features_raw = get_post_meta($p->ID, '_plan_features', true);
        $features_list = array_filter(array_map('trim', explode("\n", (string)$features_raw)));
        if (empty($features_list)) {
            $batches = (int) get_post_meta($p->ID, '_plan_batches', true);
            $students = (int) get_post_meta($p->ID, '_plan_students', true);
            $features_list = [
                ($batches === -1 ? 'Unlimited' : $batches) . ' Batches',
                ($students === -1 ? 'Unlimited' : $students) . ' Students',
                'Cloud Sync & Offline Mode',
            ];
        }

        $data[] = [
            'id'           => $p->post_name,
            'name'         => $p->post_title,
            'badge'        => get_post_meta($p->ID, '_plan_badge', true) ?: '',
            'monthlyPrice' => (float) get_post_meta($p->ID, '_plan_price', true),
            'batches'      => (int) get_post_meta($p->ID, '_plan_batches', true),
            'students'     => (int) get_post_meta($p->ID, '_plan_students', true),
            'description'  => $p->post_content,
            'features'     => array_values($features_list),
            'highlight'    => get_post_meta($p->ID, '_plan_highlight', true) === '1',
        ];
    }

    return $data;
}

/**
 * Generate Mathematically Verified SHA-256 License Key
 */
function tuition_fee_generate_license($tier, $months) {
    $salt = get_option('tuition_secret_salt', TUITION_DEFAULT_SALT);
    $clean_tier = strtoupper(trim($tier));
    $months = max(1, intval($months));

    // EXACT algorithm matching Flutter LicenseService:
    // sha256("$salt:$cleanTier:$months") -> first 4 uppercase hex characters
    $input = "{$salt}:{$clean_tier}:{$months}";
    $hash = hash('sha256', $input);
    $checksum = strtoupper(substr($hash, 0, 4));

    return "TF-{$clean_tier}-{$months}M-{$checksum}";
}

/**
 * REST API Endpoints
 */
add_action('rest_api_init', function () {
    register_rest_route('tuition/v1', '/plans', [
        'methods'             => 'GET',
        'callback'            => 'tuition_fee_rest_get_plans',
        'permission_callback' => '__return_true',
    ]);

    register_rest_route('tuition/v1', '/checkout', [
        'methods'             => 'POST',
        'callback'            => 'tuition_fee_rest_checkout',
        'permission_callback' => '__return_true',
    ]);

    register_rest_route('tuition/v1', '/verify-trx', [
        'methods'             => ['GET', 'POST'],
        'callback'            => 'tuition_fee_rest_verify_trx',
        'permission_callback' => '__return_true',
    ]);
});

function tuition_fee_rest_get_plans() {
    return rest_ensure_response(tuition_fee_get_plans_data());
}

function tuition_fee_rest_checkout($request) {
    $params = $request->get_json_params() ?: $request->get_params();
    return rest_ensure_response(tuition_fee_process_checkout($params));
}

function tuition_fee_rest_verify_trx($request) {
    $params = $request->get_json_params() ?: $request->get_params();
    $trx_id = strtoupper(trim(sanitize_text_field($params['trx_id'] ?? '')));

    if (empty($trx_id)) {
        return rest_ensure_response([
            'success'  => false,
            'verified' => false,
            'message'  => __('Please provide a Transaction ID (TrxID).', 'tuition-fee'),
        ]);
    }

    // Search tuition_order posts matching this TrxID or License Key
    $orders = get_posts([
        'post_type'      => 'tuition_order',
        'posts_per_page' => 1,
        'post_status'    => 'publish',
        'meta_query'     => [
            'relation' => 'OR',
            [
                'key'     => '_trx_id',
                'value'   => $trx_id,
                'compare' => '=',
            ],
            [
                'key'     => '_license_key',
                'value'   => $trx_id,
                'compare' => '=',
            ],
        ],
    ]);

    if (!empty($orders)) {
        $order = $orders[0];
        $plan_id = get_post_meta($order->ID, '_plan_id', true) ?: 'standard';
        $months = max(1, intval(get_post_meta($order->ID, '_months', true) ?: 1));
        $plan_name = get_post_meta($order->ID, '_plan_name', true) ?: ucfirst($plan_id) . ' Plan';
        $license_key = get_post_meta($order->ID, '_license_key', true);
        $amount = get_post_meta($order->ID, '_amount', true);

        return rest_ensure_response([
            'success'     => true,
            'verified'    => true,
            'plan_id'     => $plan_id,
            'plan_name'   => $plan_name,
            'months'      => $months,
            'validityDays'=> $months * 30,
            'license_key' => $license_key,
            'amount'      => $amount,
            'trx_id'      => $trx_id,
            'message'     => "Transaction {$trx_id} verified successfully! Activated {$plan_name}.",
        ]);
    }

    return rest_ensure_response([
        'success'  => false,
        'verified' => false,
        'message'  => "TrxID '{$trx_id}' was not found. Please verify the TrxID or contact support at 01825690912.",
    ]);
}

/**
 * AJAX Handler for Checkout
 */
function tuition_fee_ajax_checkout() {
    check_ajax_referer('tuition_fee_checkout_nonce', 'nonce');
    $response = tuition_fee_process_checkout($_POST);
    wp_send_json($response);
}
add_action('wp_ajax_tuition_checkout', 'tuition_fee_ajax_checkout');
add_action('wp_ajax_nopriv_tuition_checkout', 'tuition_fee_ajax_checkout');

/**
 * Shared Checkout Processing Function
 */
function tuition_fee_process_checkout($data) {
    $plan_id  = sanitize_text_field($data['plan_id'] ?? 'starter');
    $months   = max(1, intval($data['months'] ?? 1));
    $name     = sanitize_text_field($data['name'] ?? 'Tutor');
    $phone    = sanitize_text_field($data['phone'] ?? '');
    $email    = sanitize_email($data['email'] ?? '');
    $trx_id   = strtoupper(sanitize_text_field($data['trx_id'] ?? 'TRX' . wp_rand(100000, 999999)));
    $method   = sanitize_text_field($data['method'] ?? 'bkash');

    // Find plan details
    $plans = tuition_fee_get_plans_data();
    $found_plan = null;
    foreach ($plans as $p) {
        if ($p['id'] === $plan_id) {
            $found_plan = $p;
            break;
        }
    }
    if (!$found_plan && !empty($plans)) {
        $found_plan = $plans[0];
        $plan_id = $found_plan['id'];
    }

    $monthly_price = $found_plan ? $found_plan['monthlyPrice'] : 50;

    // Calculate discounted total
    $discount = 0.0;
    if ($months == 3) $discount = floatval(get_option('tuition_discount_3m', 0.05));
    elseif ($months == 6) $discount = floatval(get_option('tuition_discount_6m', 0.10));
    elseif ($months == 12) $discount = floatval(get_option('tuition_discount_12m', 0.20));

    $total_amount = round(($monthly_price * $months) * (1 - $discount));

    // Generate cryptographic license key
    $license_key = tuition_fee_generate_license($plan_id, $months);
    $order_num = 'ORD-' . wp_rand(100000, 999999);

    // Create tuition_order post
    $order_id = wp_insert_post([
        'post_title'  => "{$order_num} - {$license_key} ({$name})",
        'post_type'   => 'tuition_order',
        'post_status' => 'publish',
    ]);

    if ($order_id && !is_wp_error($order_id)) {
        update_post_meta($order_id, '_license_key', $license_key);
        update_post_meta($order_id, '_plan_id', $plan_id);
        update_post_meta($order_id, '_plan_name', $found_plan['name'] ?? $plan_id);
        update_post_meta($order_id, '_months', $months);
        update_post_meta($order_id, '_amount', $total_amount);
        update_post_meta($order_id, '_customer_name', $name);
        update_post_meta($order_id, '_customer_phone', $phone);
        update_post_meta($order_id, '_customer_email', $email);
        update_post_meta($order_id, '_trx_id', $trx_id);
        update_post_meta($order_id, '_payment_method', $method);
        update_post_meta($order_id, '_created_at', current_time('mysql'));
    }

    return [
        'success'      => true,
        'orderId'      => $order_num,
        'licenseKey'   => $license_key,
        'planName'     => $found_plan['name'] ?? $plan_id,
        'months'       => $months,
        'validityDays' => $months * 30,
        'batches'      => $found_plan['batches'] ?? -1,
        'students'     => $found_plan['students'] ?? -1,
        'amount'       => $total_amount,
        'trxId'        => $trx_id,
        'method'       => $method,
    ];
}

/**
 * Admin Settings Page under Settings > Tuition Store
 */
function tuition_fee_register_settings_menu() {
    add_options_page(
        __('Tuition Fee Store Settings', 'tuition-fee'),
        __('Tuition Store', 'tuition-fee'),
        'manage_options',
        'tuition-fee-settings',
        'tuition_fee_render_settings_page'
    );
}
add_action('admin_menu', 'tuition_fee_register_settings_menu');

function tuition_fee_register_settings() {
    register_setting('tuition_fee_options', 'tuition_payment_number');
    register_setting('tuition_fee_options', 'tuition_secret_salt');
    register_setting('tuition_fee_options', 'tuition_currency_symbol');
    register_setting('tuition_fee_options', 'tuition_discount_3m');
    register_setting('tuition_fee_options', 'tuition_discount_6m');
    register_setting('tuition_fee_options', 'tuition_discount_12m');
}
add_action('admin_init', 'tuition_fee_register_settings');

function tuition_fee_render_settings_page() {
    if (!current_user_can('manage_options')) return;

    // Test Key Generator Form Handling
    $test_key = '';
    if (isset($_POST['tuition_test_tier']) && isset($_POST['tuition_test_months'])) {
        check_admin_referer('tuition_test_key_nonce');
        $test_tier = sanitize_text_field($_POST['tuition_test_tier']);
        $test_months = intval($_POST['tuition_test_months']);
        $test_key = tuition_fee_generate_license($test_tier, $test_months);
    }
    ?>
    <div class="wrap">
        <h1><?php _e('Tuition Fee Store & Mobile App Verification Settings', 'tuition-fee'); ?></h1>
        <p class="description">
            <?php _e('Configure payment receiver details, discounts, and secret cryptographic salt that syncs directly with the Flutter app.', 'tuition-fee'); ?>
        </p>

        <form method="post" action="options.php">
            <?php
            settings_fields('tuition_fee_options');
            do_settings_sections('tuition_fee_options');
            ?>
            <table class="form-table">
                <tr>
                    <th scope="row"><label for="tuition_payment_number"><?php _e('bKash / Nagad Receiver Number', 'tuition-fee'); ?></label></th>
                    <td>
                        <input type="text" name="tuition_payment_number" id="tuition_payment_number" value="<?php echo esc_attr(get_option('tuition_payment_number', TUITION_DEFAULT_PAYMENT_NUMBER)); ?>" class="regular-text" />
                        <p class="description"><?php _e('Personal mobile banking number shown to users during checkout (e.g. 01825690912).', 'tuition-fee'); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="tuition_secret_salt"><?php _e('Secret Cryptographic Hash Salt', 'tuition-fee'); ?></label></th>
                    <td>
                        <input type="text" name="tuition_secret_salt" id="tuition_secret_salt" value="<?php echo esc_attr(get_option('tuition_secret_salt', TUITION_DEFAULT_SALT)); ?>" class="large-text" />
                        <p class="description">
                            <strong><?php _e('Important:', 'tuition-fee'); ?></strong>
                            <?php _e('Must exactly match the salt in Flutter <code>lib/services/license_service.dart</code>. Default: <code>TUITION_FEE_AUTH_SALT_01825690912</code>.', 'tuition-fee'); ?>
                        </p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="tuition_currency_symbol"><?php _e('Currency Symbol', 'tuition-fee'); ?></label></th>
                    <td>
                        <input type="text" name="tuition_currency_symbol" id="tuition_currency_symbol" value="<?php echo esc_attr(get_option('tuition_currency_symbol', '৳')); ?>" style="width:60px;" />
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php _e('Multi-Month Discounts', 'tuition-fee'); ?></th>
                    <td>
                        <p>
                            <label>3 Months: <input type="number" step="0.01" min="0" max="0.99" name="tuition_discount_3m" value="<?php echo esc_attr(get_option('tuition_discount_3m', '0.05')); ?>" style="width:80px;" /> (0.05 = 5% off)</label><br><br>
                            <label>6 Months: <input type="number" step="0.01" min="0" max="0.99" name="tuition_discount_6m" value="<?php echo esc_attr(get_option('tuition_discount_6m', '0.10')); ?>" style="width:80px;" /> (0.10 = 10% off)</label><br><br>
                            <label>12 Months: <input type="number" step="0.01" min="0" max="0.99" name="tuition_discount_12m" value="<?php echo esc_attr(get_option('tuition_discount_12m', '0.20')); ?>" style="width:80px;" /> (0.20 = 20% off)</label>
                        </p>
                    </td>
                </tr>
            </table>
            <?php submit_button(__('Save Store Settings', 'tuition-fee')); ?>
        </form>

        <hr style="margin:40px 0 20px;">

        <h2><?php _e('Live License Key Tester & Validator', 'tuition-fee'); ?></h2>
        <p><?php _e('Generate a real cryptographic key right now to test in your Flutter TuitionFee mobile app:', 'tuition-fee'); ?></p>

        <form method="post" action="">
            <?php wp_nonce_field('tuition_test_key_nonce'); ?>
            <div style="display:flex; align-items:center; gap:12px; margin-bottom:12px;">
                <label>
                    Tier:
                    <select name="tuition_test_tier">
                        <option value="STARTER">STARTER</option>
                        <option value="STANDARD" selected>STANDARD</option>
                        <option value="UNLIMITED">UNLIMITED</option>
                    </select>
                </label>
                <label>
                    Months:
                    <select name="tuition_test_months">
                        <option value="1">1 Month</option>
                        <option value="3" selected>3 Months</option>
                        <option value="6">6 Months</option>
                        <option value="12">12 Months</option>
                    </select>
                </label>
                <button type="submit" class="button button-primary"><?php _e('Generate Live Key', 'tuition-fee'); ?></button>
            </div>
        </form>

        <?php if ($test_key): ?>
            <div style="background:#e0e7ff; border:2px solid #6366f1; padding:16px; border-radius:8px; display:inline-block; margin-top:8px;">
                <div style="font-size:12px; color:#4338ca; font-weight:bold; margin-bottom:4px;"><?php _e('VERIFIED MATHEMATICAL KEY:', 'tuition-fee'); ?></div>
                <code style="font-size:22px; font-weight:800; color:#1e1b4b;"><?php echo esc_html($test_key); ?></code>
                <p style="margin:8px 0 0; font-size:12px; color:#3730a3;">
                    ✓ <?php _e('Copy this key and paste it into TuitionFee App > Settings > Subscription > Activate!', 'tuition-fee'); ?>
                </p>
            </div>
        <?php endif; ?>
    </div>
    <?php
}
