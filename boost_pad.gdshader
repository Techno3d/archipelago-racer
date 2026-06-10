shader_type spatial;

uniform bool activated;
uniform sampler2D texture_img : filter_nearest;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 color = texture(texture_img, vec2(0., 1.) - UV + vec2(0.,TIME * float(activated)/2.)).xyz;
	color = mix(color.bbb, color, float(activated));
	ALBEDO = vec3(color);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
