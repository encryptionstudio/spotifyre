<script lang="ts">
	import {
		faSpotify,
		faAndroid,
		faWindows,
		faApple,
		faLinux
	} from '@fortawesome/free-brands-svg-icons/index';
	import Fa from 'svelte-fa';
	import { Download, Heart } from 'lucide-svelte';
	import type { PageData } from './$types';
	import { Avatar } from '@skeletonlabs/skeleton';

	export let data: PageData;

	const formatter = new Intl.NumberFormat('en-US', {
		style: 'currency',
		currency: 'USD',
		compactDisplay: 'short',
		maximumFractionDigits: 0
	});
</script>

<svelte:head>
	<title>spotifyre</title>
	<meta name="description" content="An Open Source Spotify Client for every platform" />
	<meta name="keywords" content="spotify, client, open source, music, streaming" />
	<meta name="author" content="KRTirtho" />
	<meta name="robots" content="index, follow" />
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />
	<meta name="theme-color" content="#1DB954" />
</svelte:head>

<section class="flex flex-col gap-4 ps-4 pt-16 md:ps-24 md:pt-24">
	<div>
		<h1 class="h1">spotifyre</h1>
		<br />
		<h3 class="h3">
			An Open Source <Fa class="inline text-[#1DB954]" icon={faSpotify} /> Spotify Client for every platform
			<div class="inline-flex gap-3 items-center">
				<Fa class="inline text-[#3DDC84]" icon={faAndroid} />
				<Fa class="inline text-[#00A2F0]" icon={faWindows} />
				<Fa class="inline" icon={faLinux} />
				<Fa class="inline" icon={faApple} />
			</div>
		</h3>
		<p class="text-surface-500">
			And it's <span class="text-error-500 underline decoration-dashed">not</span>
			built with Electron (web technologies)
		</p>
		<br />
		<div class="flex items-center">
			<a href="https://play.google.com/store/apps/details?id=oss.krtirtho.spotifyre" target="_blank">
				<img
					class="-m-2"
					src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png"
					alt="Google PlayStore"
					width="200"
				/>
			</a>
			<a href="https://flathub.org/apps/com.github.KRTirtho.spotifyre" target="_blank">
				<img width="160" alt="Download on Flathub" src="https://flathub.org/api/badge?locale=en" />
			</a>
		</div>
		<br />
		<a href="https://news.ycombinator.com/item?id=39066136" target="_blank">
			<img src="https://hackerbadge.vercel.app/api?id=39066136" alt="HackerNews" />
		</a>
	</div>
	<br class="hidden md:block" />
	<div class="flex justify-center">
		<a href="/downloads" class="flex gap-2 btn variant-filled-primary">
			Download
			<Download />
		</a>
	</div>

	<br /><br />

	<h2 class="h2">
		Supporters
		<Heart class="inline-block" color="red" />
	</h2>
	<p class="text-surface-500">
		We are grateful for the support of individuals and organizations who have made spotifyre possible.
	</p>

	<div class="flex justify-center">
		<a href="https://opencollective.com/spotifyre/donate" target="_blank">
			<img
				src="https://opencollective.com/webpack/donate/button@2x.png?color=blue"
				width="300"
				alt="Open Collective"
			/>
		</a>
	</div>

	<div class="flex flex-wrap gap-4">
		{#each data.props.members as member}
			<a href={member.profile} target="_blank">
				<div
					class="flex flex-col items-center gap-2 overflow-ellipsis w-40 btn variant-ghost-secondary rounded-lg"
				>
					<Avatar src={member.image} initials={member.name} class="w-12 h-12" />
					<p>{member.name}</p>
					<p class="capitalize text-sm underline decoration-dotted">
						{formatter.format(member.totalAmountDonated)}
						({member.role.toLowerCase()})
					</p>
				</div>
			</a>
		{/each}
	</div>
</section>
