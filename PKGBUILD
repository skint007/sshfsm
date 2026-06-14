# Maintainer: skint007 <archlinux.repose742@passmail.net>
pkgname=sshm
pkgver=2.3.1
pkgrel=1
pkgdesc="SSH File System Mount Manager - simplified bash script for mounting remote servers using sshfs"
arch=('any')
url="https://github.com/skint007/sshm"
license=('MIT')
depends=('bash' 'sshfs' 'jq' 'fuse2')
optdepends=('openssh: for SSH connections')
source=('sshm'
        'sshm-completion.bash'
        'README.md')
sha256sums=('SKIP'
            'SKIP'
            'SKIP')

package() {
    # Install main script
    install -Dm755 "$srcdir/sshm" "$pkgdir/usr/bin/sshm"
    
    # Install bash completion
    install -Dm644 "$srcdir/sshm-completion.bash" "$pkgdir/etc/bash_completion.d/sshm"
    
    # Install documentation
    install -Dm644 "$srcdir/README.md" "$pkgdir/usr/share/doc/$pkgname/README.md"
}