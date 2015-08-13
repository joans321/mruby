# Download and unarchive latest Android NDK from https://developer.android.com/tools/sdk/ndk/index.html
# Make custom standalone toolchain as described here (android_ndk/docs/STANDALONE-TOOLCHAIN.html)
# Please export custom standalone toolchain path
#   export ANDROID_STANDALONE_TOOLCHAIN=/tmp/android-14-toolchain

# Add to your build_config.rb
# MRuby::CrossBuild.new('androideabi') do |conf|
#   toolchain :androideabi
# end

MRuby::Toolchain.new(:androideabi) do |conf|
  toolchain :gcc

  default_android_toolchain   = 'gcc'
  default_android_target_arch = 'arm'
  default_android_target_arch_abi = 'armeabi'
  default_android_target_platform = 'android-14'
  default_gcc_version   = '4.6'
  default_clang_version = '3.1'
  gcc_common_cflags  = %W(-ffunction-sections -funwind-tables -fstack-protector)
  gcc_common_ldflags = %W()

  # 'ANDROID_STANDALONE_TOOLCHAIN' or 'ANDROID_NDK_HOME' must be set.
  android_standalone_toolchain = ENV['ANDROID_STANDALONE_TOOLCHAIN']
  android_ndk_home = ENV['ANDROID_NDK_HOME']

  android_target_arch = ENV['ANDROID_TARGET_ARCH'] || default_android_target_arch
  android_target_arch_abi = ENV['ANDROID_TARGET_ARCH_ABI'] || default_android_target_arch_abi
  android_toolchain = ENV['ANDROID_TOOLCHAIN'] || default_android_toolchain
  gcc_version = ENV['GCC_VERSION'] || default_gcc_version
  clang_version = ENV['CLANG_VERSION'] || default_clang_version

  case android_target_arch.downcase
  when 'arch-arm',  'arm'  then
    toolchain_prefix = 'arm-linux-androideabi-'
  when 'arch-x86',  'x86'  then
    toolchain_prefix = 'i686-linux-android-'
  when 'arch-mips', 'mips' then
    toolchain_prefix = 'mipsel-linux-android-'
  else
    # Any other architectures are not supported by Android NDK.
    # Notify error.
  end

  if android_standalone_toolchain == nil then
    case RUBY_PLATFORM
    when /cygwin|mswin|mingw|bccwin|wince|emx/i
      host_platform = 'windows'
    when /x86_64-darwin/i
      host_platform = 'darwin-x86_64'
    when /darwin/i
      host_platform = 'darwin-x86'
    when /x86_64-linux/i
      host_platform = 'linux-x86_64'
    when /linux/i
      host_platform = 'linux-x86'
    else
      # Unknown host platform
    end

    android_target_platform = ENV['ANDROID_TARGET_PLATFORM'] || default_android_target_platform

    path_to_toolchain = android_ndk_home + '/toolchains/'
    path_to_sysroot   = android_ndk_home + '/platforms/' + android_target_platform
    if android_toolchain.downcase == 'gcc' then
      case android_target_arch.downcase
      when 'arch-arm',  'arm'  then
        path_to_toolchain += 'arm-linux-androideabi-'
        path_to_sysroot   += '/arch-arm'
      when 'arch-x86',  'x86'  then
        path_to_toolchain += 'x86-'
        path_to_sysroot   += '/arch-x86'
      when 'arch-mips', 'mips' then
        path_to_toolchain += 'mipsel-linux-android-'
        path_to_sysroot   += '/arch-mips'
      else
        # Any other architecture are not supported by Android NDK.
      end
      path_to_toolchain += gcc_version + '/prebuilt/' + host_platform
    else
      path_to_toolchain += 'llvm-' + clang_version + '/prebuilt/' + host_platform
    end
  else
    path_to_toolchain = android_standalone_toolchain
    path_to_sysroot   = android_standalone_toolchain + '/sysroot'
  end

  sysroot = path_to_sysroot

  case android_target_arch.downcase
  when 'arch-arm',  'arm'  then
    if android_target_arch_abi.downcase == 'armeabi-v7a' then
      arch_cflags  = %W(-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16)
      arch_ldflags = %W(-march=armv7-a -Wl,--fix-cortex-a8)
    else
      arch_cflags  = %W(-march=armv5te -mtune=xscale -msoft-float)
      arch_ldflags = %W()
    end
  when 'arch-x86',  'x86'  then
    arch_cflags  = %W()
    arch_ldflags = %W()
  when 'arch-mips', 'mips' then
    arch_cflags  = %W(-fpic -fno-strict-aliasing -finline-functions -fmessage-length=0 -fno-inline-functions-called-once -fgcse-after-reload -frerun-cse-after-loop -frename-registers)
    arch_ldflags = %W()
  else
    # Notify error
  end

  case android_toolchain.downcase
  when 'gcc' then
    android_cc = path_to_toolchain + '/bin/' + toolchain_prefix + 'gcc'
    android_ld = path_to_toolchain + '/bin/' + toolchain_prefix + 'gcc'
    android_ar = path_to_toolchain + '/bin/' + toolchain_prefix + 'ar'
    android_cflags  = gcc_common_cflags  + %W(-D__android__ -mandroid --sysroot="#{sysroot}") + arch_cflags
    android_ldflags = gcc_common_ldflags + %W(-D__android__ -mandroid --sysroot="#{sysroot}") + arch_ldflags
  when 'clang' then
    # clang is not supported yet.
  when 'clang31', 'clang3.1' then
    # clang is not supported yet.
  else
    # Any other toolchains are not supported by Android NDK.
	# Notify error.
  end

  [conf.cc, conf.cxx, conf.objc, conf.asm].each do |cc|
    cc.command = ENV['CC'] || android_cc
    cc.flags = [ENV['CFLAGS'] || android_cflags]
  end
  conf.linker.command = ENV['LD'] || android_ld
  conf.linker.flags = [ENV['LDFLAGS'] || android_ldflags]
  conf.archiver.command = ENV['AR'] || android_ar
end
