#!/bin/bash

#set -x

# Echo colors
NO_COLOR="\e[0m"
RED_COLOR="\e[1;31m"
GREEN_COLOR="\e[1;32m"
YELLOW_COLOR="\e[1;33m"
BOLD="\e[1m"
NOBOLD="\e[0m"
BLUE_BACKG="\e[44m"
INFO_MSG="[${YELLOW_COLOR}${BOLD}i${NO_COLOR}]"
GREEN_TICK="[$GREEN_COLOR✓$NO_COLOR]"
RED_CROSS="[$RED_COLOR✗$NO_COLOR]"

TOP=$(pwd)
export GIT_ASKPASS=${TOP}/git-askpass.sh

function print_help
{
	echo -e "Usage: ${0} [OPTION]"
	echo -e "\t-w, --wrl=\tWRL product version to use with the script"
	echo -e "\t-p, --path=\tUse specified path"
	echo -e "\t-i, --install\tInstall the WRL specified version"
	echo -e "\t-u, --update\tCheck for updates and install them"
	echo -e "\t-h, --help\tPrint this help"
	echo -e "\nExample: Install WRL18 on specified path:"
	echo -e "\t  ${0} -w 18 -p $(pwd)/wrl-18-mirror --install"
}

function install_wrl_mirror()
{	
	# check if user specified a path
	if [[ -z ${OPATH} ]] ; then
		echo -e "${INFO_MSG}${YELLOW_COLOR}${BOLD} Please specify a path before trying to install.${NO_COLOR}"
		exit 0
	fi
	# check if user specified WRL version
	if [[ -z ${PROD_VER} ]] ; then
		echo -e "${INFO_MSG}${YELLOW_COLOR}${BOLD} Please specify a WRL version before trying to install.${NO_COLOR}"
		exit 0
	elif [[ ${PROD_VER} != 9 && ${PROD_VER} != 17 && ${PROD_VER} != 18 && ${PROD_VER} != 19 ]] ; then
		echo -e "${INFO_MSG}${YELLOW_COLOR}${BOLD} Please stick to a supported WRL version next time (hint: 9, 17, 18, 19).${NO_COLOR}"
		exit 0
	fi
	#if specified path exists, abort
	if [[ -d ${OPATH} ]] ; then
		echo -e "${INFO_MSG}${YELLOW_COLOR}${BOLD} Specified path is already in use. Please cleanup before or use a different path for installing.${NOCOLOR}"
		echo -e "${YELLOW_COLOR}${BOLD} Maybe you want to update though (--update)?${NO_COLOR}"
		exit 0
	else
    	mkdir -p ${OPATH}
      	cd ${OPATH}
       	git clone --branch ${REL} ${REPO_URL}
       	./${REPO_DIR}/setup.sh ${WRL_OPTS}
	fi
}

function update_all_refs
{
	echo -e "${INFO_MSG}${YELLOW_COLOR}${BOLD} Updating refs${NO_COLOR}"
	git -C ${OPATH}/${REPO_DIR} remote update
	echo -e "${GREEN_TICK}${GREEN_COLOR} All refs updated.${NO_COLOR}"
}

function update_wrl_mirror
{	
	# check if user specified a path
	if [[ -z ${OPATH} ]] ; then
		echo -e "${INFO_MSG}${YELLOW_COLOR}${BOLD} Please specify a path before trying to update.${NO_COLOR}"
		exit 0
	fi
	# check if user specified WRL version
	if [[ -z ${PROD_VER} ]] ; then
		echo -e "${INFO_MSG}${YELLOW_COLOR}${BOLD} Please specify a WRL version before trying to update.${NO_COLOR}"
		exit 0
	elif [[ ${PROD_VER} != 9 && ${PROD_VER} != 17 && ${PROD_VER} != 18 && ${PROD_VER} != 19 ]] ; then
		echo -e "${INFO_MSG}${YELLOW_COLOR}${BOLD} Please stick to a supported WRL version next time (hint: 9, 17, 18, 19).${NO_COLOR}"
		exit 0
	fi
	update_all_refs
	if [[ ${PROD_VER} == 9 ]]; then
		local installed_releases=$(git -C ${OPATH}/${REPO_DIR} branch | grep LTS_CVE_RCPL | awk -F '_' '{print $5}' | sed s/RCPL0000// )
		local available_releases=$(git -C ${OPATH}/${REPO_DIR} branch -a | grep remote | grep LTS_CVE_RCPL | awk -F '_' '{print $5}' | sed s/RCPL0000// )
	else
		local installed_releases=$(git -C ${OPATH}/${REPO_DIR} branch | grep LTS_RCPL | awk -F '_' '{print $5}' | sed s/RCPL0000// )
		local available_releases=$(git -C ${OPATH}/${REPO_DIR} branch -a | grep remote | grep LTS_RCPL | awk -F '_' '{print $5}' | sed s/RCPL0000// )
	fi

	local needed_releases=$(echo ${installed_releases} ${available_releases} | tr ' ' '\n' | sort | uniq -u | paste -sd' ')

	echo -e "${INFO_MSG}${YELLOW_COLOR}${BOLD} Installed RCPLs:${NO_COLOR} $(echo ${installed_releases})"
	echo -e "${INFO_MSG}${YELLOW_COLOR}${BOLD} Available RCPLs for install:${GREEN_COLOR}${BOLD} $(echo ${needed_releases})${NO_COLOR}"

	if [[ -z ${needed_releases} ]] ; then
		echo -e "${INFO_MSG} No missing RCPLs, nothing to do here.${NO_COLOR}"
	else
		readarray -t needed_releases <<< ${needed_releases}
		for i in ${needed_releases[@]} ; do
			echo -e "${INFO_MSG}${YELLOW_COLOR}${BOLD} Updating with ${GREEN_COLOR}${i}${NO_COLOR}"
			local ulog=update_WRL${PROD_VER}_${i}_$(date +%d_%m_%Y).log
			git -C ${OPATH}/${REPO_DIR} checkout ${BRANCH}${i} > /dev/null
			git -C ${OPATH}/${REPO_DIR} pull > /dev/null
			cd ${OPATH}
			${OPATH}/${REPO_DIR}/setup.sh ${WRL_OPTS} > ${TOP}/${ulog} 2>&1
			if [[ $? == 0 ]] ; then
				echo -e "\n${GREEN_TICK} Updated with ${GREEN_COLOR}${BOLD}${i}${NO_COLOR}."
			else
				echo -e "\n${RED_CROSS} Update with ${i} failed, check ${ulog}."
			fi
		done
	fi
}

# if no argument is given, print help
if [[ $# == 0 ]] ; then
	print_help
	exit 0
fi

# handle CMD arguments
while [ "$#" -gt 0 ]; do
	case "$1" in
		-w) PROD_VER="$2"; shift 2;;
		-p) OPATH="$2"; shift 2;;
		-i) OINSTALL="yes"; shift 1;;
		-u) OUPDATE="yes"; shift 1;;
		-h) print_help ; exit 0 ;;

		--wrl=*) PROD_VER="${1#*=}"; shift 1;;
		--path=*) OPATH="${1#*=}"; shift 1;;
		--install) OINSTALL="yes"; shift 1;;
		--update) OUPDATE="yes"; shift 1;;
		--help) print_help ; exit 0;;
		--wrl|--path) echo "$1 requires an argument" >&2; exit 0;;

		-*) echo "unknown option: $1" >&2; exit 1;;
		*) print_help ; exit 0;;
	esac
done

# make sure git password is set as ENV VAR before using the script
if [[ -z ${GIT_PASSWORD} ]] ; then
	echo -e "${INFO_MSG}${YELLOW_COLOR}${BOLD} Please export your WR password to the GIT_PASSWORD env var before using this script.${NO_COLOR}"
	exit 0
fi

if [[ ${PROD_VER} == 9 ]]; then
	REPO_DIR="wrlinux-9"
	REPO_URL="https://windshare.windriver.com/remote.php/gitsmart/WRLinux-9-LTS-CVE/wrlinux-9"
	REL="WRLINUX_9_LTS_CVE"
	WRL_OPTS="--machines qemux86-64 --accept-eula yes --all-layers --dl-layers --distros=wrlinux --user=${WUSER} --password=${GIT_PASSWORD}"
	BRANCH=WRLINUX_9_LTS_CVE_
elif [[ ! -z ${PROD_VER} ]] ; then
	REPO_DIR="wrlinux-x"
	REPO_URL="https://windshare.windriver.com/remote.php/gitsmart/WRLinux-lts-${PROD_VER}-Core/wrlinux-x"
	REL="WRLINUX_10_${PROD_VER}_LTS"
	WRL_OPTS="--machines qemux86-64 --accept-eula yes --no-anspass --mirror --all-layers --dl-layers --distros=wrlinux --user=${WUSER} --password=${GIT_PASSWORD}"
	BRANCH=WRLINUX_10_${PROD_VER}_LTS_
fi

if [[ ! -z ${OINSTALL} && -z ${OUPDATE} ]]; then
	install_wrl_mirror
elif [[ ! -z ${OUPDATE} && -z ${OINSTALL} ]]; then
	update_wrl_mirror
elif [[ ! -z ${OUPDATE}  && ! -z ${OINSTALL} ]]; then
	echo -e "${INFO_MSG}${YELLOW_COLOR}${BOLD} You can either update or install, can't do both at the same time.${NO_COLOR}"
	exit 0
fi
