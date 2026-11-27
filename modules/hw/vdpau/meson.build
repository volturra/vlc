# VDPAU modules

vdpau_dep = dependency('vdpau', version: '>= 0.6', required: get_option('vdpau'))

if not vdpau_dep.found()
    subdir_done()
endif

if not x11_dep.found()
    if get_option('vdpau').enabled()
        error('VDPAU requires Xlib (X11).')
    endif
    subdir_done()
endif

vlc_vdpau_lib = shared_library('vlc_vdpau',
    files('vlc_vdpau.c'),
    include_directories: [vlc_include_dirs],
    link_args: gc_sections_linkargs,
    dependencies: [vdpau_dep, x11_dep, dl_lib],
    version: '0.0.0',
    install: true,
    install_dir: pkglibdir_path,
)

vlc_modules += {
    'name' : 'vdpau_instance',
    'sources' : files('device.c'),
    'dependencies' : [vdpau_dep, x11_dep],
    'link_with' : [vlc_vdpau_lib],
    'install_rpath' : pkglibdir_path,
    'plugin_dir' : 'vdpau',
}

vlc_modules += {
    'name' : 'vdpau_avcodec',
    'sources' : files('avcodec.c', 'picture.c'),
    'dependencies' : [vdpau_dep, avcodec_dep, avutil_dep],
    'link_with' : [vlc_vdpau_lib],
    'install_rpath' : pkglibdir_path,
    'plugin_dir' : 'vdpau',
    'enabled' : avcodec_dep.found(),
}

foreach vdpau_filter : ['deinterlace', 'adjust', 'sharpen', 'chroma']
    vlc_modules += {
        'name' : 'vdpau_' + vdpau_filter,
        'sources' : files(vdpau_filter + '.c', 'picture.c'),
        'dependencies' : [vdpau_dep],
        'link_with' : [vlc_vdpau_lib],
        'install_rpath' : pkglibdir_path,
        'plugin_dir' : 'vdpau',
    }
endforeach

# VDPAU GLX interop
vlc_modules += {
    'name' : 'glinterop_vdpau',
    'sources' : files(
        '../../video_output/opengl/interop_vdpau.c',
        'picture.c',
    ),
    'dependencies' : [
        gl_common_dep.partial_dependency(compile_args: true, includes: true),
        vdpau_dep, x11_dep, dl_lib,
    ],
    'link_with' : [vlc_vdpau_lib],
    'install_rpath' : pkglibdir_path,
    'plugin_dir' : 'video_output',
    'enabled' : opengl_dep.found(),
}
