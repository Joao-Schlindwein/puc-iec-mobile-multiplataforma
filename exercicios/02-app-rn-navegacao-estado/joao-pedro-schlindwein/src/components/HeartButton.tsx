// src/components/HeartButton.tsx
//
// ATIVIDADE 2 — TASK 8 (Reanimated não-trivial, opção A: Heart pop)
//
// Tocar ❤️ → escala spring (1 → 1.4 → 1.0) + rotação leve. Worklet puro,
// roda direto na UI thread (useSharedValue + useAnimatedStyle), sem a
// Animated API legado.
//
// Doc: https://docs.swmansion.com/react-native-reanimated/

import { Pressable, StyleSheet, Text } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSequence,
  withSpring,
  withTiming,
} from 'react-native-reanimated';

type Props = {
  active: boolean;
  onPress: () => void;
};

export default function HeartButton({ active, onPress }: Props) {
  const scale = useSharedValue(1);
  const rotate = useSharedValue(0);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }, { rotateZ: `${rotate.value}deg` }],
  }));

  const handlePress = () => {
    scale.value = withSequence(withTiming(1.4, { duration: 120 }), withSpring(1));
    rotate.value = withSequence(
      withTiming(-15, { duration: 60 }),
      withTiming(15, { duration: 80 }),
      withSpring(0)
    );
    onPress();
  };

  return (
    <Pressable
      onPress={(e) => {
        e.stopPropagation();
        handlePress();
      }}
      style={styles.heart}
    >
      <Animated.Text style={[styles.heartIcon, animatedStyle]}>
        {active ? '❤️' : '🤍'}
      </Animated.Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  heart: { padding: 8 },
  heartIcon: { fontSize: 24 },
});
