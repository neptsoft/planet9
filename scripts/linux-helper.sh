#!/bin/bash

PLANET9_HOME=/var/planet9
PLANET9_SERVICE_NAME="Planet 9"
PLANET9_SERVICE_FILENAME="planet9"
PLANET9_SERVICE_PATH=/etc/systemd/system/${PLANET9_SERVICE_FILENAME}.service
PLANET9_USER=planet9
# Note Debian/Ubuntu uses 'nogroup', RHEL/Fedora uses 'nobody'
PLANET9_GROUP=nobody

if [ $EUID -ne 0 ]; then
    echo "$0 is not running as root. This is needed to create the user and set up systemd. Aborting."
    exit 2
fi

echo "Starting the Planet9 installation script"

if [ -z $(pidof -s systemd) ]; then
    echo "This script only supports systemd at this time"
    exit 1
fi

if [ "$#" -ne 1 ]; then
    echo "Usage: "
    echo "--install: Installs Planet9 as a systemd service in '${PLANET9_SERVICE_PATH}'"
    echo "--uninstall: Removed Planet9 and all of its files (the entire contents of '${PLANET9_HOME}' is removed)"
    echo "--upgrade: Runs the Planet9 upgrade system"
    exit 1
fi

if [ "$1" == "--uninstall" ]; then
    echo "Uninstalling Planet9"
    echo ""
    echo "This will remove EVERYTHING in ${PLANET9_HOME} and the service file ${PLANET9_SERVICE_PATH}"
    read -p "Continue (y/n)?" CONT
    if [ "$CONT" != "y" ]; then
        echo "Aborting uninstallation"
        exit 0
    fi
    systemctl disable ${PLANET9_SERVICE_FILENAME}
    if [ $? -ne 0 ]; then
        echo "Unable to disable the systemd service '${PLANET9_SERVICE_FILENAME}"
        exit 1
    fi
    rm -f ${PLANET9_SERVICE_PATH}
    if [ $? -ne 0 ]; then
        echo "Unable to remove the systemd service '${PLANET9_SERVICE_PATH}"
        exit 1
    fi
    rm -rf ${PLANET9_HOME}
    if [ $? -ne 0 ]; then
        echo "Unable to remove the Planet9 directory '${PLANET9_HOME}"
        exit 1
    fi
    exit 0
fi

if [ "$1" == "--upgrade" ]; then
    if [ ! -d "${PLANET9_HOME}" ]; then
        echo "The Planet9 directory '${PLANET9_HOME}' does not exist"
        exit 1
    fi

    systemctl stop ${PLANET9_SERVICE_FILENAME}
    if [ $? -ne 0 ]; then
        echo "Unable to stop the service '${PLANET9_SERVICE_FILENAME}'"
        exit 1
    fi

    sudo -u ${PLANET9_USER} cp planet9-linux ${PLANET9_HOME}
    if [ $? -ne 0 ]; then
        echo "Unable to copy the Planet9 file to '${PLANET9_HOME}'"
        exit 1
    fi
    cd ${PLANET9_HOME}
    sudo -u ${PLANET9_USER} ./planet9-linux --upgrade
    if [ $? -ne 0 ]; then
        echo "Upgrade failed. Please save this log and contact Neptune Software"
        exit 1
    fi
    systemctl start ${PLANET9_SERVICE_FILENAME}
    exit 0
fi

echo "This will setup the systemd service in '${PLANET9_SERVICE_PATH}' as '${PLANET9_SERVICE_NAME}' with the user '${PLANET9_USER}' and group '${PLANET9_GROUP}', in addition to installing Planet9 in '${PLANET9_HOME}'"
read -p "Continue (y/n)?" CONT
if [ "$CONT" != "y" ]; then
    echo "Aborting installation"
    exit 0
fi

if [ ! -f planet9-linux ]; then
    echo "The file 'planet9-linux' needs to be in the same directory as this script"
    exit 1
fi

echo "Installing Planet9 as \"${PLANET9_SERVICE_NAME}\" to ${PLANET9_HOME}..."

if [ -z $(getent passwd ${PLANET9_USER}) ]; then
    echo "Adding user ${PLANET9_USER}"
    useradd -m -s /usr/bin/nologin ${PLANET9_USER}
    if [ $? -ne 0 ]; then
        echo "Unable to create user ${PLANET9_USER}"
        exit 1
    fi
fi

mkdir -p ${PLANET9_HOME}/log/exceptions
mkdir -p ${PLANET9_HOME}/log/scripts
mkdir -p ${PLANET9_HOME}/log/server
mkdir -p ${PLANET9_HOME}/config
mkdir -p ${PLANET9_HOME}/.tmp

if [ $? -ne 0 ]; then
    echo "Unable to create directories"
    exit 1
fi

cp planet9-linux ${PLANET9_HOME}
if [ $? -ne 0 ]; then
    echo "Unable to copy 'planet9-linux' to ${PLANET9_HOME}"
    exit 1
fi

chown ${PLANET9_USER}:${PLANET9_GROUP} -R ${PLANET9_HOME}

if [ $? -ne 0 ]; then
    echo "Unable to change the ownership of ${PLANET9_HOME} to ${PLANET9_USER}:${PLANET9_GROUP}"
    exit 1
fi

PLANET9_SERVICE_CONTENT="
[Unit]
Description=${PLANET9_SERVICE_NAME}

[Service]
ExecStart=${PLANET9_HOME}/planet9-linux
Restart=always
User=${PLANET9_USER}
Group=${PLANET9_GROUP}
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
WorkingDirectory=${PLANET9_HOME}

[Install]
WantedBy=multi-user.target"

echo "${PLANET9_SERVICE_CONTENT}" | tee ${PLANET9_SERVICE_PATH} > /dev/null

if [ $? -ne 0 ]; then
    echo "Unable to generate the service file in ${PLANET9_SERVICE_PATH}"
    exit 1
fi

systemctl enable ${PLANET9_SERVICE_FILENAME}
if [ $? -ne 0 ]; then
    echo "Unable to enable the service '${PLANET9_SERVICE_FILENAME}'"
    exit 1
fi
systemctl daemon-reload
if [ $? -ne 0 ]; then
    echo "Unable to reload the systemd daemon"
    exit 1
fi

echo ""
echo ""
echo "Planet9 installed successfully"
echo "=============================="
echo ""
echo "Planet9 installed as '${PLANET9_SERVICE_FILENAME}' to '${PLANET9_HOME}' as user '${PLANET9_USER}' and group '${PLANET9_GROUP}'"
echo "To start your Planet9 installation, execute 'sudo systemctl start ${PLANET9_SERVICE_FILENAME}'"
echo "To stop your Planet9 installation, execute 'sudo systemctl stop ${PLANET9_SERVICE_FILENAME}'"
echo "To restart your Planet9 installation, execute 'sudo systemctl restart ${PLANET9_SERVICE_FILENAME}'"
echo "To see the status of your Planet9 installation, execute 'systemctl status ${PLANET9_SERVICE_FILENAME}'"
echo "To view the logs, execute 'journalctl -u ${PLANET9_SERVICE_FILENAME}'"
echo "To stream the logs, execute 'journalctl -u ${PLANET9_SERVICE_FILENAME} -f'"
echo ""
echo "Please remember that the files under ${PLANET9_HOME} must remain owned by '${PLANET9_USER}' - otherview permission problems might arise"
echo ""
echo "If the release requires you to upgrade the database, either run this script with '--upgrade' or follow these steps before starting Planet9 again:"
echo "sudo systemctl stop ${PLANET9_SERVICE_FILENAME}"
echo "cp planet9-linux ${PLANET9_HOME}"
echo "cd ${PLANET9_HOME}"
echo "./planet9-linux --upgrade"
