<script lang="ts">
	import { FaSignOutAlt } from 'svelte-icons/fa';
	export let logout;
</script>

<button
	type="button"
	on:click={logout}
	style="position:absolute;top:5vw;right:5vw;width:7.5vw;height:7.5vw;display:flex;align-items:center;justify-content:center;cursor:pointer;z-index:10;background:transparent;border:0;color:black;"
	aria-label="Logout"
	class="logout-icon"
	on:keydown={(e) => {
		if (e.key === 'Enter' || e.key === ' ') logout();
	}}
>
	<FaSignOutAlt />
</button>

<style>
</style>
