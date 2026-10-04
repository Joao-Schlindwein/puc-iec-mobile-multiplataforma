// src/components/AnimatedPoster.tsx
//
// ATIVIDADE 2 — TASK 8, opção C (shared element simplificado).
//
// Ao entrar em MovieDetail, o poster "cresce" de uma escala menor até o
// tamanho final com withSpring — efeito tipo Apple Music ao abrir um álbum.
// Worklet puro: useSharedValue + useAnimatedStyle, roda na UI thread.

import { useEffect } from 'react';
import { Image, StyleSheet, type ImageStyle } from 'react-native';
import Animated, { useAnimatedStyle, useSharedValue, withSpring } from 'react-native-reanimated';

type Props = {
  uri: string;
  style: ImageStyle;
};

export default function AnimatedPoster({ uri, style }: Props) {
  const scale = useSharedValue(0.6);
  const opacity = useSharedValue(0);

  useEffect(() => {
    scale.value = withSpring(1, { damping: 14, stiffness: 120 });
    opacity.value = withSpring(1);
  }, []);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
    opacity: opacity.value,
  }));

  return (
    <Animated.View style={animatedStyle}>
      <Image source={{ uri }} style={[styles.poster, style]} />
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  poster: {},
});
