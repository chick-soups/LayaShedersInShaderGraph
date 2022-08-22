float4x4 LayaLocalTranfrom(float3 position, float3 angles, float3 scale) {
	float3 rotate= radians(angles);
	float3 c = cos(rotate);
	float3 s = sin(rotate);

	float4x4 rotX = float4x4(1.0, 0.0, 0.0, 0.0, 0.0, c.x, s.x, 0.0, 0.0, -s.x, c.x, 0.0, 0.0, 0.0, 0.0, 1.0);
	float4x4 rotY = float4x4(c.y, 0.0, -s.y, 0.0, 0.0, 1.0, 0.0, 0.0, s.y, 0.0, c.y, 0.0, 0.0, 0.0, 0.0, 1.0);
	float4x4 rotZ = float4x4(c.z, s.z, 0.0, 0.0, -s.z, c.z, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0);
	float4x4 mScale = float4x4(scale.x, 0.0, 0.0, 0.0, 0.0, scale.y, 0.0, 0.0, 0.0, 0.0, scale.z,0.0, 0.0, 0.0, 0.0, 1.0);
	float4x4 mtransfrom = float4x4(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, position.x, position.y, position.z, 1.0);
	return mtransfrom * rotZ * rotX * rotY * mScale;
}
