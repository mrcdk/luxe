package luxe.debug;

import luxe.Input;
import luxe.Text;
import luxe.Screen.WindowEvent;
import luxe.resource.Resource;
import luxe.Resources;
import luxe.tween.Actuate;
import luxe.utils.Maths;
import phoenix.Shader;
import phoenix.Texture;

class StatsDebugView extends luxe.debug.DebugView  {

    public var _last_render_stats : RenderStats;
    public var _render_stats : RenderStats;

    public var debug_draw_call_count : Int = 3;
    public var debug_geometry_count : Int = 13;
    public var font_size : Int = 15;

        //stats console
    public var render_stats_text : luxe.Text;
    public var resource_list_text : luxe.Text;

    public function new() {

        super();

        name = 'Statistics';

        _last_render_stats = {
            batchers : 0,
            geometry_count : 0,
            dynamic_batched_count : 0,
            static_batched_count : 0,
            visible_count : 0,
            draw_calls : 0,
            vert_count : 0
        };

        _render_stats = {
            batchers : 0,
            geometry_count : 0,
            dynamic_batched_count : 0,
            static_batched_count : 0,
            visible_count : 0,
            draw_calls : 0,
            vert_count : 0
        };

    } //new

    public function get_resource_stats_string() {

        return Std.string( Luxe.resources.stats );

    } //get_resource_stats_string

    public function get_render_stats_string() {

        return
            'Renderer Statistics\n\n' +
            'batcher count : ' + _render_stats.batchers + '\n' +
            'total geometry : ' + _render_stats.geometry_count + '\n' +
            'visible geometry : ' + _render_stats.visible_count + '\n' +
            'dynamic batch count : ' + _render_stats.dynamic_batched_count + '\n' +
            'static batch count : ' + _render_stats.static_batched_count + '\n' +
            'total draw calls : ' + _render_stats.draw_calls + '\n' +
            'total vert count : ' + _render_stats.vert_count;

    } //get_render_stats_string

    var margin = 32;
    public override function create() {

        var debug = Luxe.debug;

        render_stats_text = new luxe.Text({
            name:'debug.render.stats',
            depth : 999.3,
            no_scene : true,
            color : new Color(0,0,0,1).rgb(0xf6007b),
            pos : new Vector(0,0),
            font : Luxe.renderer.font,
            text : get_render_stats_string(),
            point_size : font_size,
            batcher : debug.batcher,
            visible : false,
        });

        resource_list_text = new luxe.Text({
            name:'debug.resource.stats',
            depth : 999.3,
            no_scene : true,
            color : new Color(0,0,0,1).rgb(0xf6007b),
            pos : new Vector(0,0),
            font : Luxe.renderer.font,
            text : '',
            align : TextAlign.right,
            point_size : font_size*0.9,
            batcher : debug.batcher,
            visible : false,
        });

        render_stats_text.geometry.id = 'debug.render.stats.geometry';
        render_stats_text.geometry.id = 'debug.resource.stats.geometry';

        resize();

        Luxe.resources.on(ResourceEvent.any, function(_) if(visible) refresh() );

    } //create

    function resize() {

        if( resource_list_text == null ||
            render_stats_text == null) {
            return;
        }

        var debug = Luxe.debug;

        var viewrect = new Rectangle(
            debug.inspector.pos.x + (margin/2),
            debug.inspector.pos.y + (margin*1.5),
            debug.inspector.size.x - margin,
            debug.inspector.size.y - margin - (margin*1.5)
        );

        var left = debug.padding.x + margin;
        var right = debug.padding.x + debug.inspector.size.x - margin;
        var top = debug.padding.y +(margin*1.5);
        var render_w = render_stats_text.text_bounds.w;
        var render_h = render_stats_text.text_bounds.h;

        if(resource_list_text != null) {
            resource_list_text.pos = new Vector(right, top);
            resource_list_text.clip_rect = viewrect;
        }

        if(render_stats_text != null) {
            render_stats_text.pos = new Vector(left, top);
            render_stats_text.clip_rect = viewrect;
        }

        reset_tween();

    }

    override function onwindowsized(e:WindowEvent) resize();

    public override function refresh() {

        var bytes_lists = '';
        var text_lists = '';
        var json_lists = '';
        var texture_lists = '';
        var rtt_lists = '';
        var font_lists = '';
        var shader_lists = '';

        inline function _res(res:Resource) return '${res.id} • ${res.ref}\t\n';
        inline function _tex(tex:Texture) return '(${tex.width_actual}x${tex.height_actual} ~${Luxe.utils.bytes_to_string(tex.memory_use())})    ${tex.id} • ${tex.ref}\t\n';
        inline function _shd(res:Shader) return '(${res.vert_id}, ${res.frag_id})    ${res.id} • ${res.ref}\t\n';

        for(res in Luxe.resources.cache) {
            switch(res.resource_type) {
                case ResourceType.bytes:            bytes_lists += _res(res);
                case ResourceType.text:             text_lists += _res(res);
                case ResourceType.json:             json_lists += _res(res);
                case ResourceType.texture:          texture_lists += _tex(cast res);
                case ResourceType.render_texture:   rtt_lists += _tex(cast res);
                case ResourceType.font:             font_lists += _res(res);
                case ResourceType.shader:           shader_lists += _shd(cast res);
                default:
            }
        }

        inline function orblank(v:String) return (v == '') ? '-\t\n' : v;

        var lists = 'Resource list (${Luxe.resources.stats.total})\n\n';

            lists += 'Bytes (${Luxe.resources.stats.bytes})\n';
                lists += orblank(bytes_lists);
            lists += '\nText (${Luxe.resources.stats.texts})\n';
                lists += orblank(text_lists);
            lists += '\nJSON (${Luxe.resources.stats.jsons})\n';
                lists += orblank(json_lists);
            lists += '\nTexture (${Luxe.resources.stats.textures})\n';
                lists += orblank(texture_lists);
            lists += '\nRenderTexture (${Luxe.resources.stats.render_textures})\n';
                lists += orblank(rtt_lists);
            lists += '\nFont (${Luxe.resources.stats.fonts})\n';
                lists += orblank(font_lists);
            lists += '\nShader (${Luxe.resources.stats.shaders})\n';
                lists += orblank(shader_lists);

        //add the sounds, those are not resources in the same manner, but for now

        var sound_list = '';
        var _sounds:Array<String> = [];

            for(sound in Luxe.snow.audio.sound_list) _sounds.push(sound.name);
            _sounds.sort(function(a:String,b:String) {
                if(a == b) return 0;
                if(a < b) return -1;
                return 1;
            });
            for(sound in _sounds) {
                sound_list += '$sound •\n';
            }


            var _count = Lambda.count(Luxe.snow.audio.sound_list);
            lists += '\n\n---\nAudio list ($_count)\n\n';
                lists += orblank(sound_list);

        resource_list_text.text = lists;

        if(resource_list_text.geometry != null) {
            resource_list_text.geometry.dirty = true;
        }

        reset_tween();

    } //refresh

    public override function process() {

        if(!visible) return;

        var dirty = false;

            //Update the local statistics
        update_render_stats();

        if(_last_render_stats.batchers != _render_stats.batchers)
            { dirty = true; _last_render_stats.batchers = _render_stats.batchers; }
        if(_last_render_stats.geometry_count != _render_stats.geometry_count)
            { dirty = true; _last_render_stats.geometry_count = _render_stats.geometry_count; }
        if(_last_render_stats.dynamic_batched_count != _render_stats.dynamic_batched_count)
            { dirty = true; _last_render_stats.dynamic_batched_count = _render_stats.dynamic_batched_count; }
        if(_last_render_stats.static_batched_count != _render_stats.static_batched_count)
            { dirty = true; _last_render_stats.static_batched_count = _render_stats.static_batched_count; }
        if(_last_render_stats.visible_count != _render_stats.visible_count)
            { dirty = true; _last_render_stats.visible_count = _render_stats.visible_count; }
        if(_last_render_stats.draw_calls != _render_stats.draw_calls)
            { dirty = true; _last_render_stats.draw_calls = _render_stats.draw_calls; }
        if(_last_render_stats.vert_count != _render_stats.vert_count)
            { dirty = true; _last_render_stats.vert_count = _render_stats.vert_count; }

        if(dirty) {
            refresh_render_stats();
        } //dirty

    } //process

#if (desktop || web)
    //:wip:
    override function onmousewheel(e:MouseEvent) {

        Actuate.stop(resource_list_text.pos);

        var h = resource_list_text.text_bounds.h;
        var vh = Luxe.debug.inspector.size.y - margin;
        var diff = h - vh;

        var new_y = resource_list_text.pos.y;
        var max_y = Luxe.debug.padding.y +(margin*1.5);
        var min_y = max_y;

        if(diff > 0) {
            min_y = (max_y - (diff+(margin*2)));
        }

        new_y -= (margin/2) * e.y;
        new_y = Maths.clamp(new_y, min_y, max_y);
        resource_list_text.pos.y = new_y;

    }
#end

    public override function onkeydown(e:KeyEvent) {

        if(e.keycode == Key.key_2 && visible) {
            toggle_debug_stats();
        }

    } //onkeydown

    public override function show() {

        super.show();
        refresh();
        render_stats_text.visible = true;
        resource_list_text.visible = true;

    } //show

    public override function hide() {

        super.hide();
        render_stats_text.visible = false;
        resource_list_text.visible = false;
        Actuate.stop(resource_list_text.pos);

    } //hide

    function reset_tween() {

        Actuate.stop(resource_list_text.pos);

        var h = resource_list_text.text_bounds.h;
        var vh = Luxe.debug.inspector.size.y - margin;
        var diff = h - vh;

        var start_y = Luxe.debug.padding.y +(margin*1.5);
        resource_list_text.pos.y = start_y;

        if(diff > 0) {
            var end_y = (start_y - (diff+(margin*2)));
            Actuate.tween(resource_list_text.pos, 8, { y:end_y }).repeat().delay(4).reflect().ease(luxe.tween.easing.Linear.easeNone);
        }

    }

   public function refresh_render_stats() {

        if(!visible) {
            return;
        }

        render_stats_text.text = get_render_stats_string();

        render_stats_text.locked = true;

        if(render_stats_text.geometry != null) {
            render_stats_text.geometry.dirty = true;
        }

    } //refresh_render_stats

    public var hide_debug : Bool = true;
    public function toggle_debug_stats() {

         hide_debug = !hide_debug;

    } //toggle_debug_stats

    public function update_render_stats() {

        debug_geometry_count = Luxe.debug.batcher.geometry.size();
        debug_draw_call_count = Luxe.debug.batcher.draw_calls;

        _render_stats.batchers = Luxe.renderer.stats.batchers;
        _render_stats.geometry_count = Luxe.renderer.stats.geometry_count;
        _render_stats.visible_count = Luxe.renderer.stats.visible_count;
        _render_stats.dynamic_batched_count = Luxe.renderer.stats.dynamic_batched_count;
        _render_stats.static_batched_count = Luxe.renderer.stats.static_batched_count;
        _render_stats.draw_calls = Luxe.renderer.stats.draw_calls;
        _render_stats.vert_count = Luxe.renderer.stats.vert_count;

        if(hide_debug) {

            _render_stats.geometry_count = _render_stats.geometry_count - debug_geometry_count;
            _render_stats.visible_count = _render_stats.visible_count - Luxe.debug.batcher.visible_count;
            _render_stats.dynamic_batched_count = _render_stats.dynamic_batched_count - Luxe.debug.batcher.dynamic_batched_count;// - Luxe.debug.batcher.static_batched_count;
            _render_stats.static_batched_count = _render_stats.static_batched_count - Luxe.debug.batcher.static_batched_count;
            _render_stats.draw_calls -= debug_draw_call_count;
            _render_stats.vert_count -= Luxe.debug.batcher.vert_count;

        } //hide debug stats?

    } //update_render_stats

} //StatsDebugView

typedef RenderStats = {
    batchers : Int,
    geometry_count : Int,
    dynamic_batched_count : Int,
    static_batched_count : Int,
    visible_count : Int,
    draw_calls : Int,
    vert_count : Int,
}
