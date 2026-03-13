<script lang="ts">
	import { onMount, onDestroy, tick } from 'svelte';
	import type { User } from 'oidc-client-ts';
	interface TokenDetails {
		name: string;
		discord: string;
		bricklink: string;
		effective_date: string;
		expiration_date: string;
	}
	export let user: User | null;
	export let tokenDetails: TokenDetails | null;
	let canvas: HTMLCanvasElement;
	let debouncedDraw: () => void;
	let fontsLoaded = false;
	let fontsLoadPromise: Promise<void> | null = null;

	async function ensureFontsLoaded() {
		if (fontsLoaded) {
			return;
		}
		if (fontsLoadPromise) {
			return fontsLoadPromise;
		}
		if (typeof document === 'undefined' || !('fonts' in document)) {
			fontsLoaded = true;
			return;
		}

		const fontDescriptors = ['700 1rem "Outfit"', '400 1rem "Outfit"'];
		fontsLoadPromise = (async () => {
			try {
				const pendingFonts = fontDescriptors.filter(
					(descriptor) => !document.fonts.check(descriptor)
				);
				if (pendingFonts.length > 0) {
					await Promise.all(pendingFonts.map((descriptor) => document.fonts.load(descriptor)));
					await document.fonts.ready;
				}
			} catch (error) {
				console.warn('Unable to load fonts for membership card rendering', error);
			} finally {
				fontsLoaded = true;
			}
		})();

		return fontsLoadPromise;
	}

	function debounce<T extends (...args: unknown[]) => void>(func: T, wait: number) {
		let timeout: ReturnType<typeof setTimeout>;
		return function (this: unknown, ...args: Parameters<T>) {
			clearTimeout(timeout);
			timeout = setTimeout(() => func.apply(this, args), wait);
		};
	}

	onMount(async () => {
		debouncedDraw = debounce(drawCanvas, 250);
		window.addEventListener('resize', debouncedDraw);
		await tick();
		await ensureFontsLoaded();
		drawCanvas();
	});

	onDestroy(() => {
		if (debouncedDraw) {
			window.removeEventListener('resize', debouncedDraw);
		}
	});

	let figureImg: HTMLImageElement | null = null;
	let logoImg: HTMLImageElement | null = null;

	// Preload figure.png and logo.svg

	onMount(() => {
		figureImg = new window.Image();
		figureImg.src = 'figure.png';
		figureImg.onload = () => drawCanvas();
		logoImg = new window.Image();
		logoImg.src = 'logo.svg';
		logoImg.onload = () => drawCanvas();
	});

	// Redraw canvas only when user, tokenDetails, figureImg, or logoImg change
	$: if (canvas && user && tokenDetails && figureImg && logoImg && fontsLoaded) {
		drawCanvas();
	}

	function drawCanvas() {
		if (!canvas || !user || !tokenDetails || !fontsLoaded) return;
		const ctx = canvas.getContext('2d');
		if (!ctx) return;
		const dpr = window.devicePixelRatio || 1;
		const rect = canvas.parentElement!.getBoundingClientRect();
		canvas.width = rect.width * dpr;
		canvas.height = (rect.width / 1.58) * dpr;
		ctx.scale(dpr, dpr);
		canvas.style.width = `${rect.width}px`;
		canvas.style.height = `${rect.width / 1.58}px`;
		ctx.fillStyle = '3887be';
		// ctx.fillStyle = '#ffffff';
		const cornerRadius = 20 / dpr;
		const width = rect.width;
		const height = rect.height;

		// Draw card bkackground
		ctx.beginPath();
		ctx.moveTo(cornerRadius, 0);
		ctx.lineTo(width - cornerRadius, 0);
		ctx.quadraticCurveTo(width, 0, width, cornerRadius);
		ctx.lineTo(width, height - cornerRadius);
		ctx.quadraticCurveTo(width, height, width - cornerRadius, height);
		ctx.lineTo(cornerRadius, height);
		ctx.quadraticCurveTo(0, height, 0, height - cornerRadius);
		ctx.lineTo(0, cornerRadius);
		ctx.quadraticCurveTo(0, 0, cornerRadius, 0);
		ctx.closePath();
		//ctx.fillStyle = '#52d3d8';
		//ctx.fillStyle = '#F2CD37';
		ctx.fillStyle = '#ffffff';
		ctx.fill();

		// Draw left yellow circle (only top right quarter visible)
		const leftCircleRadius = width * 0.5;
		const leftCircleX = width * -0.1;
		const leftCircleY = height * 1.37;
		ctx.save();
		ctx.beginPath();
		ctx.arc(leftCircleX, leftCircleY, leftCircleRadius, 0, Math.PI * 2);
		ctx.clip();
		ctx.beginPath();
		ctx.arc(leftCircleX, leftCircleY, leftCircleRadius, 0, Math.PI * 2);
		// ctx.fillStyle = '#f2f597';
		//ctx.fillStyle = '#000000';
		ctx.fill();
		ctx.restore();

		// Draw right blue circle (much bigger, only left half visible)
		const rightCircleRadius = width * 0.7;
		const rightCircleX = width * 1 + rightCircleRadius * 0.4;
		const rightCircleY = height * 0.8;
		ctx.save();
		ctx.beginPath();
		ctx.arc(rightCircleX, rightCircleY, rightCircleRadius, Math.PI * 0.5, Math.PI * 1.5);
		ctx.lineTo(width, 0);
		ctx.lineTo(width, height);
		ctx.closePath();
		ctx.clip();
		ctx.beginPath();
		ctx.arc(rightCircleX, rightCircleY, rightCircleRadius, 0, Math.PI * 2);
		ctx.fillStyle = '#C91A09';
		ctx.fillStyle = '#F2CD37';
		ctx.fill();
		ctx.restore();

		// Draw logo.svg in the lower left corner
		if (logoImg && logoImg.complete) {
			const logoSize = width * 0.25 * 1.5;
			const logoScale = logoSize / logoImg.width;
			const logoX = width * 0.025;
			const logoY = height - logoSize + height * -0.388;
			ctx.drawImage(logoImg, logoX, logoY, logoSize, logoImg.height * logoScale);
		}

		// Draw figure.png on the right side of the card
		if (figureImg && figureImg.complete) {
			// Set image size relative to card size
			const imgWidth = width * 0.5;
			const imgHeight = imgWidth * (figureImg.naturalHeight / figureImg.naturalWidth);
			const imgX = width - imgWidth + width * 0.0;
			const imgY = height * 0.3;
			ctx.drawImage(figureImg, imgX, imgY, imgWidth, imgHeight);
		}

		const baseFontSize = width / 20;
		ctx.font = `700 ${baseFontSize * 1}px 'Outfit', sans-serif`;
		ctx.textAlign = 'left';
		ctx.fillStyle = 'black';
		ctx.fillText('JÄSENKORTTI', width * 0.52, height * 0.145);
		ctx.font = `700 ${baseFontSize * 1.2}px 'Outfit', sans-serif`;
		ctx.fillStyle = 'black';
		ctx.textAlign = 'center';
		ctx.fillText(`${tokenDetails?.name.split(' ', 2)[0]}`, width * 0.25, height * 0.475);
		ctx.fillText(`${tokenDetails?.name.split(' ', 2)[1]}`, width * 0.25, height * 0.6);
		ctx.textAlign = 'left';
		ctx.font = `700 ${baseFontSize * 0.6}px 'Outfit', sans-serif`;
		ctx.fillStyle = '#000000';
		ctx.fillText(
			`Voimassaolo päättyy: ${tokenDetails?.expiration_date || ''}`,
			width * 0.03,
			height * 0.925
		);
		ctx.fillText(
			`Liittymispäivä: ${tokenDetails?.effective_date || ''}`,
			width * 0.03,
			height * 0.85
		);
		//ctx.fillText(`Discord: ${tokenDetails?.discord || ''}`, width * 0.04, height * 0.6);
		ctx.fillText(`Bricklink: ${tokenDetails?.bricklink || ''}`, width * 0.03, height * 0.775);
	}
</script>

<canvas bind:this={canvas} class="border"></canvas>
