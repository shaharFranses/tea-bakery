# PKD slim web export template
`pkd_web_release_slim.zip` (if present) is a custom Godot 4.3-stable (77dcf97d8) web **release** template, single-thread,
built from the profile in `pkd_slim_2d.py` (copied here). `tools/sync_presets.py` sets it as `custom_template/release`
when the file exists; `PKD_STOCK=1 tools/build_web.sh release` forces the stock template.
Scope: 2D-only (`disable_3d`), fallback text server (Latin, no RTL/complex shaping), and none of these modules: astcenc,
basis_universal, bmp, camera, csg, cvtt, dds, enet, etcpak, fbx, glslang, gltf, gridmap, hdr, interactive_music, jsonrpc,
ktx, lightmapper_rd, mbedtls, meshoptimizer, mobile_vr, msdfgen, multiplayer, navigation, noise, openxr, raycast, squish,
tga, theora, tinyexr, upnp, vhacd, webrtc, websocket, webxr, xatlas_unwrap, zip.
Kept: gdscript, freetype, svg, webp, jpg, ogg/vorbis, minimp3, regex, 2D physics, GL Compatibility renderer.
A game that needs 3D, RTL text, MSDF fonts, websockets/WebRTC or OGV video must use the stock template (or a different profile).
Rebuild: see `/workspace/pipeline-ops/engine/build_slim.sh` on the box (emsdk 3.1.64, scons 4.8.1).
