#!python -u

import getopt
import os
import subprocess
import sys

def clone(repo, url):
    cmd = ['git', 'clone', url, repo]

    if os.path.exists(repo):
        return True

    sub = subprocess.Popen(cmd, stdout=subprocess.PIPE)
    output = sub.communicate()[0]
    ret = sub.returncode

    if ret != 0:
        raise(Exception("Error %d in : %s" % (ret, cmd)))

    return True

def shell(command, dir):
    print(dir)
    print(command)
    sys.stdout.flush()

    sub = subprocess.Popen(' '.join(command), cwd=dir,
                           stdout=None,
                           stderr=subprocess.STDOUT)
    sys.stdout.flush()
    sub.wait()

    return sub.returncode

def default_environment(key, value):
    current_value = os.environ.get(key, None)
    if current_value == None:
        os.environ[key] = value
        return value
    return current_value

def configure_visual_studio():
    path = default_environment('VS', 'C:\\Program Files (x86)\\Microsoft Visual Studio 14.0')
    if not os.path.exists(path):
        print('visual studio 14.0 (2015) is not installed, or VS is set incorrectly: %s' % (path))
        sys.exit(1)
    print('VS: %s' % (path))

def configure_win10_ddk():
    path = default_environment('KIT', 'C:\\Program Files (x86)\\Windows Kits\\10')
    if not os.path.exists(path):
        print('windows 10 ddk is not installed, or KIT is set incorrectly: %s' % (path))
        sys.exit(1)
    print('KIT: %s' % (path))

def configure_symbols_path():
    path = default_environment('SYMBOL_SERVER', 'C:\\Symbols')
    print('SYMBOL_SERVER: %s' % (path))

def configure_dpinst_path():
    path = default_environment('DPINST_REDIST', 'C:\\Program Files (x86)\\Windows Kits\\8.1\\Redist\\DIFx\\dpinst\\EngMui')
    if not os.path.exists(path):
        print('windows 8.1 ddk is not installed, or DPINST_REDIST is set incorrectly: %s' % (path))
        sys.exit(1)
    print('DPINST_REDIST: %s' % (path))

def configure_environment():
    configure_visual_studio()
    configure_win10_ddk()
    configure_symbols_path()
    configure_dpinst_path()

def main():
    repos = { 'xenbus': 'git://xenbits.xen.org/pvdrivers/win/xenbus.git',
              'xencons': 'git://xenbits.xen.org/pvdrivers/win/xencons.git',
              'xenhid': 'git://xenbits.xen.org/pvdrivers/win/xenhid.git',
              'xeniface': 'git://xenbits.xen.org/pvdrivers/win/xeniface.git',
              'xennet': 'git://xenbits.xen.org/pvdrivers/win/xennet.git',
              'xenvbd': 'git://xenbits.xen.org/pvdrivers/win/xenvbd.git',
              'xenvif': 'git://xenbits.xen.org/pvdrivers/win/xenvif.git',
              'xenvkbd': 'git://xenbits.xen.org/pvdrivers/win/xenvkbd.git',
              'xenvusb': 'ssh://github.com/cjp256/xenvusb.git' }

    try:
        opts, args = getopt.getopt(sys.argv[1:], "hr:", ["help", "repo="])
    except getopt.GetoptError as err:
        # print help information and exit:
        print(str(err))  # will print something like "option -a not recognized"
        usage()
        sys.exit(2)

    selected_repos = repos.copy()
    for o, a in opts:
        if o in ("-h", "--help"):
            print('%s [-r <repo-to-build>] [-h]' % (sys.argv[0]))
            sys.exit(0)
        elif o in ("-r", "--repo"):
            if a not in repos:
                print('error: unknown repo %s' % (a))
                sys.exit(1)
            print('selected repo: %s' % (a))
            selected_repos = {}
            selected_repos[a] = repos[a]
        else:
            assert False, "unhandled option"

    configure_environment()

    for repo, url in selected_repos.items():
        clone(repo, url)

    for repo, url in selected_repos.items():
        shell(['python', 'build.py', 'checked', 'nosdv'], os.path.abspath(repo))

if __name__ == '__main__':
    main()
