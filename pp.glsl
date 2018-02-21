extern vec2 roffset;
extern vec2 goffset;
extern vec2 boffset;
extern float time;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
  if (sin(screen_coords.y * 10 + time * 0.1) > 0) {
    texture_coords += vec2(tan(time * 0.5 + screen_coords.y * 10) * 0.00001, 0.0);
  }
  vec4 pixelr = Texel(texture, texture_coords + roffset);
  vec4 pixelg = Texel(texture, texture_coords + goffset);
  vec4 pixelb = Texel(texture, texture_coords + boffset);
  /* return pixelr; */
  return vec4(pixelr.r * float(pixelr.a > 0), pixelg.g * pixelg.a, pixelb.b * pixelb.a, 1.0);
}
