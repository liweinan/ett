function checkBzAuthFieldsNotEmpty(id) {
    if (id) {
        var bzauth_user = document.getElementById('bzauth_user_' + id);
        var bzauth_pwd = document.getElementById('bzauth_pwd_' + id);
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

function checkPackageVersionFormat(ver) {
    return ver.match(/[\d\.a-zA-Z\-_]+/) == ver;
}

function checkBzAuthInfo(id, beforeStatus) {
    var afterStatusElement;

    if (id) {
        afterStatusElement = document.getElementById('package_status_id_' + id);
    } else {
        afterStatusElement = document.getElementById('package_status_id');
    }

    var afterStatus;
    if (afterStatusElement) {
        afterStatus = afterStatusElement.value;
    }

    if (beforeStatus != afterStatus) { // user has changed status
        if (!checkBzAuthFieldsNotEmpty(id)) {
            alert('Please provide your Bugzilla account and password.');
            return false;
        }
    }
    return true;
}