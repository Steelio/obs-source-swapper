#include <obs-module.h>
#include <obs-frontend-api.h>
#include <util/platform.h>
#include <windows.h>

OBS_DECLARE_MODULE()
OBS_MODULE_USE_DEFAULT_LOCALE("source_toggler", "en-US")

struct source_switcher_data {
	int hotkey;
	bool last_key_state;
	char *main_source_name;
	char *alternate_source_name;
	bool is_alternate_active;
};

static struct source_switcher_data *g_switcher = NULL;

static void set_source_visibility(const char *source_name, bool visible)
{
	if (!source_name || strlen(source_name) == 0) return;
	obs_source_t *source = obs_get_source_by_name(source_name);
	if (!source) {
		blog(LOG_WARNING, "Source '%s' not found", source_name);
		return;
	}
	obs_source_t *scene_source = obs_frontend_get_current_scene();
	if (!scene_source) {
		obs_source_release(source);
		return;
	}
	obs_scene_t *scene = obs_scene_from_source(scene_source);
	if (!scene) {
		obs_source_release(scene_source);
		obs_source_release(source);
		return;
	}
	obs_sceneitem_t *item = obs_scene_find_source(scene, source_name);
	if (item) {
		obs_sceneitem_set_visible(item, visible);
		blog(LOG_INFO, "%s source: %s", visible ? "Showing" : "Hiding", source_name);
	} else {
		blog(LOG_WARNING, "Source '%s' not found in current scene", source_name);
	}

	obs_source_release(scene_source);
	obs_source_release(source);
}




static void check_hotkey_state(void *data, float seconds)
{
	UNUSED_PARAMETER(data);
	UNUSED_PARAMETER(seconds);

	if (!g_switcher) return;

	struct source_switcher_data *switcher = g_switcher;
	SHORT key_state = GetAsyncKeyState(switcher->hotkey);
	bool key_pressed = (key_state & 0x8000) != 0;

	if (key_pressed != switcher->last_key_state) {
		if (key_pressed && !switcher->is_alternate_active) {
			set_source_visibility(switcher->main_source_name, false);
			set_source_visibility(switcher->alternate_source_name, true);
			switcher->is_alternate_active = true;
		} else if (!key_pressed && switcher->is_alternate_active) {
			set_source_visibility(switcher->alternate_source_name, false);
			set_source_visibility(switcher->main_source_name, true);
			switcher->is_alternate_active = false;
		}
	}

	switcher->last_key_state = key_pressed;
}

static const char *source_switcher_get_name(void *unused)
{
	UNUSED_PARAMETER(unused);
	return "Map Hider";
}

static void source_switcher_update(void *data, obs_data_t *settings)
{
	struct source_switcher_data *switcher = data;

	switcher->hotkey = (int)obs_data_get_int(settings, "hotkey");
	if (switcher->hotkey == 0)
		switcher->hotkey = VK_TAB;

	const char *main = obs_data_get_string(settings, "main_source");
	const char *alt = obs_data_get_string(settings, "alternate_source");

	bfree(switcher->main_source_name);
	bfree(switcher->alternate_source_name);

	switcher->main_source_name = main ? bstrdup(main) : NULL;
	switcher->alternate_source_name = alt ? bstrdup(alt) : NULL;

	blog(LOG_INFO, "Source toggler updated - Hotkey: %d, Main: '%s', Alt: '%s'",
		switcher->hotkey,
		switcher->main_source_name ? switcher->main_source_name : "(none)",
		switcher->alternate_source_name ? switcher->alternate_source_name : "(none)");
}

static void *source_switcher_create(obs_data_t *settings, obs_source_t *source)
{
	UNUSED_PARAMETER(source);

	struct source_switcher_data *switcher = bzalloc(sizeof(struct source_switcher_data));
	switcher->is_alternate_active = false;
	switcher->last_key_state = false;

	g_switcher = switcher;
	source_switcher_update(switcher, settings);

	return switcher;
}

static void source_switcher_destroy(void *data)
{
	struct source_switcher_data *switcher = data;
	if (g_switcher == switcher)
		g_switcher = NULL;

	bfree(switcher->main_source_name);
	bfree(switcher->alternate_source_name);
	bfree(switcher);

	blog(LOG_INFO, "Source toggler destroyed");
}

static obs_properties_t *source_switcher_properties(void *data)
{
	UNUSED_PARAMETER(data);
	obs_properties_t *props = obs_properties_create();

	obs_property_t *hotkey_prop = obs_properties_add_list(props, "hotkey", "Hold Hotkey",
		OBS_COMBO_TYPE_LIST, OBS_COMBO_FORMAT_INT);

	obs_property_list_add_int(hotkey_prop, "TAB", VK_TAB);
	obs_property_list_add_int(hotkey_prop, "Shift", VK_SHIFT);
	obs_property_list_add_int(hotkey_prop, "Ctrl", VK_CONTROL);
	obs_property_list_add_int(hotkey_prop, "Alt", VK_MENU);
	for (int c = 'A'; c <= 'Z'; ++c)
		obs_property_list_add_int(hotkey_prop, (char[]){(char)c, 0}, c);

	obs_properties_add_text(props, "main_source", "Main Source Name", OBS_TEXT_DEFAULT);
	obs_properties_add_text(props, "alternate_source", "Alternate Source Name (Map Hidden)", OBS_TEXT_DEFAULT);

	return props;
}

static void source_switcher_get_defaults(obs_data_t *settings)
{
	obs_data_set_default_int(settings, "hotkey", VK_TAB);
	obs_data_set_default_string(settings, "main_source", "");
	obs_data_set_default_string(settings, "alternate_source", "");
}

static struct obs_source_info source_switcher_info = {
	.id = "source_visibility_toggler",
	.type = OBS_SOURCE_TYPE_INPUT,
	.output_flags = OBS_SOURCE_DO_NOT_DUPLICATE,
	.get_name = source_switcher_get_name,
	.create = source_switcher_create,
	.destroy = source_switcher_destroy,
	.update = source_switcher_update,
	.get_properties = source_switcher_properties,
	.get_defaults = source_switcher_get_defaults,
};

bool obs_module_load(void)
{
	obs_register_source(&source_switcher_info);
	obs_add_tick_callback(check_hotkey_state, NULL);
	blog(LOG_INFO, "Source Visibility Toggler plugin loaded");
	return true;
}

void obs_module_unload(void)
{
	obs_remove_tick_callback(check_hotkey_state, NULL);
	blog(LOG_INFO, "Source Visibility Toggler plugin unloaded");
}
