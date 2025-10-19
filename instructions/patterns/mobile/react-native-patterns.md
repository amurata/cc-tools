# React Native Patterns

Mobile development patterns for React Native applications.

## Project Structure

### Scalable Folder Structure
```
src/
  components/
    common/
      Button.tsx
      Input.tsx
    screens/
      HomeScreen.tsx
      ProfileScreen.tsx
  navigation/
    AppNavigator.tsx
    AuthNavigator.tsx
  services/
    api.ts
    storage.ts
  hooks/
    useAuth.ts
    useLocation.ts
  utils/
    constants.ts
    helpers.ts
  store/
    slices/
      authSlice.ts
    store.ts
```

## Navigation Patterns

### React Navigation Setup
```typescript
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';

// Type definitions
export type RootStackParamList = {
  Home: undefined;
  Profile: { userId: string };
  Settings: undefined;
};

export type TabParamList = {
  Feed: undefined;
  Search: undefined;
  Profile: undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();
const Tab = createBottomTabNavigator<TabParamList>();

// Tab Navigator
function TabNavigator() {
  return (
    <Tab.Navigator
      screenOptions={{
        tabBarActiveTintColor: '#007AFF',
        tabBarInactiveTintColor: 'gray',
      }}
    >
      <Tab.Screen 
        name="Feed" 
        component={FeedScreen}
        options={{
          tabBarIcon: ({ color, size }) => (
            <Icon name="home" color={color} size={size} />
          ),
        }}
      />
      <Tab.Screen name="Search" component={SearchScreen} />
      <Tab.Screen name="Profile" component={ProfileScreen} />
    </Tab.Navigator>
  );
}

// Main Navigator
export default function AppNavigator() {
  return (
    <NavigationContainer>
      <Stack.Navigator>
        <Stack.Screen 
          name="Main" 
          component={TabNavigator} 
          options={{ headerShown: false }}
        />
        <Stack.Screen name="Settings" component={SettingsScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
```

## State Management

### Redux Toolkit with React Native
```typescript
import { configureStore, createSlice, PayloadAction } from '@reduxjs/toolkit';
import { useDispatch, useSelector, TypedUseSelectorHook } from 'react-redux';

// Auth slice
const authSlice = createSlice({
  name: 'auth',
  initialState: {
    user: null as User | null,
    token: null as string | null,
    isLoading: false,
  },
  reducers: {
    loginStart: (state) => {
      state.isLoading = true;
    },
    loginSuccess: (state, action: PayloadAction<{ user: User; token: string }>) => {
      state.user = action.payload.user;
      state.token = action.payload.token;
      state.isLoading = false;
    },
    loginFailure: (state) => {
      state.isLoading = false;
    },
    logout: (state) => {
      state.user = null;
      state.token = null;
    },
  },
});

// Store
export const store = configureStore({
  reducer: {
    auth: authSlice.reducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;

// Typed hooks
export const useAppDispatch = () => useDispatch<AppDispatch>();
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector;
```

## Platform-Specific Code

### Platform Detection
```typescript
import { Platform, StyleSheet } from 'react-native';

// Platform-specific styles
const styles = StyleSheet.create({
  container: {
    paddingTop: Platform.select({
      ios: 20,
      android: 0,
    }),
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
      },
      android: {
        elevation: 4,
      },
    }),
  },
});

// Platform-specific components
const MyComponent = () => {
  return (
    <>
      {Platform.OS === 'ios' ? (
        <IOSSpecificComponent />
      ) : (
        <AndroidSpecificComponent />
      )}
    </>
  );
};

// Platform-specific files
// Button.ios.tsx
// Button.android.tsx
// React Native will automatically pick the right file
```

## Performance Optimization

### List Optimization
```typescript
import { FlatList, VirtualizedList } from 'react-native';

// Optimized FlatList
function OptimizedList({ data }) {
  const renderItem = useCallback(({ item }) => (
    <ListItem item={item} />
  ), []);
  
  const keyExtractor = useCallback((item) => item.id, []);
  
  const getItemLayout = useCallback((data, index) => ({
    length: ITEM_HEIGHT,
    offset: ITEM_HEIGHT * index,
    index,
  }), []);
  
  return (
    <FlatList
      data={data}
      renderItem={renderItem}
      keyExtractor={keyExtractor}
      getItemLayout={getItemLayout}
      maxToRenderPerBatch={10}
      updateCellsBatchingPeriod={50}
      initialNumToRender={10}
      windowSize={10}
      removeClippedSubviews={true}
      onEndReachedThreshold={0.5}
      onEndReached={loadMore}
    />
  );
}
```

### Image Optimization
```typescript
import FastImage from 'react-native-fast-image';

// Cached and optimized images
function OptimizedImage({ uri, style }) {
  return (
    <FastImage
      style={style}
      source={{
        uri,
        priority: FastImage.priority.normal,
        cache: FastImage.cacheControl.immutable,
      }}
      resizeMode={FastImage.resizeMode.cover}
    />
  );
}

// Image preloading
const preloadImages = (urls: string[]) => {
  const images = urls.map(uri => ({ uri }));
  FastImage.preload(images);
};
```

## Native Module Integration

### Custom Native Module
```typescript
// NativeModules/MyModule.ts
import { NativeModules, NativeEventEmitter } from 'react-native';

interface MyNativeModule {
  multiply(a: number, b: number): Promise<number>;
  startLocationUpdates(): void;
  stopLocationUpdates(): void;
}

const { MyNativeModule } = NativeModules;
const eventEmitter = new NativeEventEmitter(MyNativeModule);

// Wrapper with TypeScript
class MyModule {
  multiply(a: number, b: number): Promise<number> {
    return MyNativeModule.multiply(a, b);
  }
  
  startLocationUpdates(callback: (location: Location) => void) {
    const subscription = eventEmitter.addListener('onLocationUpdate', callback);
    MyNativeModule.startLocationUpdates();
    return subscription;
  }
  
  stopLocationUpdates() {
    MyNativeModule.stopLocationUpdates();
  }
}

export default new MyModule();
```

## Storage Patterns

### Async Storage with Encryption
```typescript
import AsyncStorage from '@react-native-async-storage/async-storage';
import CryptoJS from 'crypto-js';

class SecureStorage {
  private secretKey = 'your-secret-key';
  
  async setItem(key: string, value: any): Promise<void> {
    try {
      const jsonValue = JSON.stringify(value);
      const encrypted = CryptoJS.AES.encrypt(jsonValue, this.secretKey).toString();
      await AsyncStorage.setItem(key, encrypted);
    } catch (e) {
      console.error('Error saving data', e);
    }
  }
  
  async getItem<T>(key: string): Promise<T | null> {
    try {
      const encrypted = await AsyncStorage.getItem(key);
      if (!encrypted) return null;
      
      const decrypted = CryptoJS.AES.decrypt(encrypted, this.secretKey);
      const jsonValue = decrypted.toString(CryptoJS.enc.Utf8);
      return JSON.parse(jsonValue);
    } catch (e) {
      console.error('Error reading data', e);
      return null;
    }
  }
  
  async removeItem(key: string): Promise<void> {
    try {
      await AsyncStorage.removeItem(key);
    } catch (e) {
      console.error('Error removing data', e);
    }
  }
}

export default new SecureStorage();
```

## API Integration

### API Service with Interceptors
```typescript
import axios, { AxiosInstance } from 'axios';
import NetInfo from '@react-native-community/netinfo';

class ApiService {
  private api: AxiosInstance;
  
  constructor() {
    this.api = axios.create({
      baseURL: 'https://api.example.com',
      timeout: 10000,
    });
    
    this.setupInterceptors();
  }
  
  private setupInterceptors() {
    // Request interceptor
    this.api.interceptors.request.use(
      async (config) => {
        // Check network connectivity
        const netInfo = await NetInfo.fetch();
        if (!netInfo.isConnected) {
          throw new Error('No internet connection');
        }
        
        // Add auth token
        const token = await SecureStorage.getItem('token');
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        
        return config;
      },
      (error) => Promise.reject(error)
    );
    
    // Response interceptor
    this.api.interceptors.response.use(
      (response) => response,
      async (error) => {
        if (error.response?.status === 401) {
          // Handle token refresh
          await this.refreshToken();
        }
        return Promise.reject(error);
      }
    );
  }
  
  async get<T>(url: string): Promise<T> {
    const response = await this.api.get<T>(url);
    return response.data;
  }
  
  async post<T>(url: string, data: any): Promise<T> {
    const response = await this.api.post<T>(url, data);
    return response.data;
  }
}

export default new ApiService();
```

## Animation Patterns

### Reanimated 2 Animations
```typescript
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
  interpolate,
  runOnJS,
} from 'react-native-reanimated';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';

function SwipeableCard({ onSwipe }) {
  const translateX = useSharedValue(0);
  const translateY = useSharedValue(0);
  
  const gesture = Gesture.Pan()
    .onUpdate((event) => {
      translateX.value = event.translationX;
      translateY.value = event.translationY;
    })
    .onEnd(() => {
      if (Math.abs(translateX.value) > 120) {
        translateX.value = withSpring(translateX.value > 0 ? 500 : -500);
        runOnJS(onSwipe)(translateX.value > 0 ? 'right' : 'left');
      } else {
        translateX.value = withSpring(0);
        translateY.value = withSpring(0);
      }
    });
  
  const animatedStyle = useAnimatedStyle(() => {
    const rotate = interpolate(
      translateX.value,
      [-200, 0, 200],
      [-15, 0, 15]
    );
    
    return {
      transform: [
        { translateX: translateX.value },
        { translateY: translateY.value },
        { rotate: `${rotate}deg` },
      ],
    };
  });
  
  return (
    <GestureDetector gesture={gesture}>
      <Animated.View style={[styles.card, animatedStyle]}>
        {/* Card content */}
      </Animated.View>
    </GestureDetector>
  );
}
```

## Testing

### Component Testing
```typescript
import React from 'react';
import { render, fireEvent, waitFor } from '@testing-library/react-native';
import { NavigationContainer } from '@react-navigation/native';

describe('MyComponent', () => {
  it('should render correctly', () => {
    const { getByText, getByTestId } = render(
      <NavigationContainer>
        <MyComponent />
      </NavigationContainer>
    );
    
    expect(getByText('Welcome')).toBeTruthy();
  });
  
  it('should handle button press', async () => {
    const mockFn = jest.fn();
    const { getByTestId } = render(
      <MyComponent onPress={mockFn} />
    );
    
    fireEvent.press(getByTestId('submit-button'));
    
    await waitFor(() => {
      expect(mockFn).toHaveBeenCalled();
    });
  });
});
```

## Checklist
- [ ] Set up navigation structure
- [ ] Configure state management
- [ ] Handle platform differences
- [ ] Optimize list performance
- [ ] Implement secure storage
- [ ] Set up API integration
- [ ] Add error boundaries
- [ ] Configure push notifications