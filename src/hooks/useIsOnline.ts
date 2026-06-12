import NetInfo from '@react-native-community/netinfo';
import { useEffect, useState } from 'react';

/**
 * True while the device has a network connection. Defaults to true (unknown
 * state should not flash the offline banner), same as the Flutter app.
 */
export function useIsOnline(): boolean {
  const [isOnline, setIsOnline] = useState(true);

  useEffect(() => {
    const unsubscribe = NetInfo.addEventListener((state) => {
      setIsOnline(state.isConnected !== false);
    });
    return unsubscribe;
  }, []);

  return isOnline;
}
