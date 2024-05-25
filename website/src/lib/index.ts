import {
	faAndroid,
	faApple,
	faDebian,
	faFedora,
	faOpensuse,
	faUbuntu,
	faWindows,
	faRedhat
} from '@fortawesome/free-brands-svg-icons';
import { type IconDefinition } from '@fortawesome/free-brands-svg-icons/index';
import { Home, Newspaper, Download } from 'lucide-svelte';

export const routes: Record<string, [string, any]> = {
	'/': ['Home', Home],
	'/blog': ['Blog', Newspaper],
	'/downloads': ['Downloads', Download],
	'/about': ['About', null]
};

const releasesUrl = 'https://github.com/KRTirtho/spotifyre/releases/latest/download';

export const downloadLinks: Record<string, [string, IconDefinition[]]> = {
	'Android Apk': [`${releasesUrl}/spotifyre-android-all-arch.apk`, [faAndroid]],
	'Windows Executable': [`${releasesUrl}/spotifyre-windows-x86_64-setup.exe`, [faWindows]],
	'macOS Dmg': [`${releasesUrl}/spotifyre-macos-universal.dmg`, [faApple]],
	'Ubuntu, Debian': [`${releasesUrl}/spotifyre-linux-x86_64.deb`, [faUbuntu, faDebian]],
	'Fedora, Redhat, Opensuse': [
		`${releasesUrl}/spotifyre-linux-x86_64.rpm`,
		[faFedora, faRedhat, faOpensuse]
	],
	'iPhone Ipa': [`${releasesUrl}/spotifyre-iOS.ipa`, [faApple]]
};

export const extendedDownloadLinks: Record<string, [string, IconDefinition[], string]> = {
	Android: [`${releasesUrl}/spotifyre-android-all-arch.apk`, [faAndroid], 'apk'],
	Windows: [`${releasesUrl}/spotifyre-windows-x86_64-setup.exe`, [faWindows], 'exe'],
	macOS: [`${releasesUrl}/spotifyre-macos-universal.dmg`, [faApple], 'dmg'],
	'Ubuntu, Debian': [`${releasesUrl}/spotifyre-linux-x86_64.deb`, [faUbuntu, faDebian], 'deb'],
	'Fedora, Redhat, Opensuse': [
		`${releasesUrl}/spotifyre-linux-x86_64.rpm`,
		[faFedora, faRedhat, faOpensuse],
		'rpm'
	],
	iPhone: [`${releasesUrl}/spotifyre-iOS.ipa`, [faApple], 'ipa']
};

const nightlyReleaseUrl = 'https://github.com/KRTirtho/spotifyre/releases/download/nightly';

export const extendedNightlyDownloadLinks: Record<string, [string, IconDefinition[], string]> = {
	Android: [`${nightlyReleaseUrl}/spotifyre-android-all-arch.apk`, [faAndroid], 'apk'],
	Windows: [`${nightlyReleaseUrl}/spotifyre-windows-x86_64-setup.exe`, [faWindows], 'exe'],
	macOS: [`${nightlyReleaseUrl}/spotifyre-macos-universal.dmg`, [faApple], 'dmg'],
	'Ubuntu, Debian': [`${nightlyReleaseUrl}/spotifyre-linux-x86_64.deb`, [faUbuntu, faDebian], 'deb'],
	'Fedora, Redhat, Opensuse': [
		`${nightlyReleaseUrl}/spotifyre-linux-x86_64.rpm`,
		[faFedora, faRedhat, faOpensuse],
		'rpm'
	],
	iPhone: [`${nightlyReleaseUrl}/spotifyre-iOS.ipa`, [faApple], 'ipa']
};
