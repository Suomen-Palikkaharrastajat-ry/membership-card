<script lang="ts">
	import { FaSignInAlt } from 'svelte-icons/fa';
	import { login } from '../lib/auth';
</script>

<div class="space-y-6 text-center"></div>

<div class="centered-icon">
	<button
		class="login-button"
		type="button"
		aria-label="Kirjaudu"
		on:click={login}
		style="background:none;border:none;padding:0;cursor:pointer;color: #F2CD37;"
	>
		<FaSignInAlt size="10vw" />
		<h1 style="text-transform:uppercase">Avaa tästä</h1>
	</button>
</div>

<style>
	.centered-icon {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		height: 100vh;
		width: 100vw;
		background: transparent;
	}
</style>
