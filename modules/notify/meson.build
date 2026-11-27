# Notification modules

# libnotify
libnotify_dep = dependency('libnotify', required: get_option('notify'))
vlc_modules += {
    'name' : 'notify',
    'sources' : files('notify.c'),
    'dependencies' : [libnotify_dep],
    'plugin_dir' : 'notify',
    'enabled' : libnotify_dep.found(),
}
