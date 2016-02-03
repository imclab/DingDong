﻿Shader "Hidden/Motion" {
	Properties {
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader {
		Cull Off ZWrite Off ZTest Always
		Pass {
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag
			#include "UnityCG.cginc"
			#define PI 3.1415926535897
			
			sampler2D _MainTex;
			sampler2D _MotionTexture;
			sampler2D _WebcamTexture;
			sampler2D _WebcamTextureLast;

			float _TresholdMotion;
			float _FadeOutRatio;
			float _SplashesRatio;
			float2 _CollisionPosition;
			float2 _Resolution;
			float _BonusSize;
			float2 _BonusPosition;
			float4 _BonusColor;

			// http://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
			float rand (float2 co) {
			  return frac(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
			}

			fixed4 frag (v2f_img i) : SV_Target 
			{
				fixed4 col = fixed4(1,1,1,1);
				
				float2 position = _BonusPosition - i.uv;
				position.x *= _Resolution.x / _Resolution.y;
				float circle = step(length(position), _BonusSize);
				col.rgb = lerp(col.rgb, _BonusColor, circle);

				float2 uv = i.uv;

				// From position
				position = uv - _CollisionPosition;
				uv -= normalize(position) * 0.01 * _SplashesRatio;

				// Brush
				float angle = rand(position) * PI * 2.;
				uv += float2(cos(angle), sin(angle)) * 0.002 * _SplashesRatio;

				// River
				angle = Luminance(tex2D(_WebcamTexture, i.uv)) * PI * 2.;
				uv += float2(cos(angle), sin(angle)) * 0.005 * _SplashesRatio;

				float current = Luminance(tex2D(_WebcamTexture, uv));
				float last = Luminance(tex2D(_WebcamTextureLast, uv));

				float4 motion = fixed4(1,1,1,1);
				motion.rgb *= step(_TresholdMotion, abs(current - last));

				float4 fadeOut = fixed4(1,1,1,1);
				fadeOut.rgb = lerp(tex2D(_MotionTexture, uv).rgb, _BonusColor, circle);
				fadeOut.rgb *= lerp(_FadeOutRatio, 1, _SplashesRatio);

				col.rgb = lerp(fadeOut, motion, step(0.5, motion));

				return col;
			}
			ENDCG
		}
	}
}