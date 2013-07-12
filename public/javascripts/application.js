function checkBzAuthFieldsNotEmpty(id) {
    if (id) {
        // todo complete it
        return false;
    } else {
        var bzauth_user = document.getElementById('bzauth_user');
        var bzauth_pwd = document.getElementById('bzauth_pwd');

        if (bzauth_user) {
            if (bzauth_pwd) {
                if (bzauth_user.value) {
                    if (bzauth_pwd.value) {
                        return true;
                    }
                }
            }
        }
        return false;
    }
}
