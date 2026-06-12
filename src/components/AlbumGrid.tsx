import { FlatList, StyleSheet, useWindowDimensions } from 'react-native';
import type { ComponentProps } from 'react';

import { gridColumns, spacing } from '../constants/theme';
import type { Album } from '../types/catalog';
import { AlbumCard } from './AlbumCard';

type FlatListExtras = Pick<
  ComponentProps<typeof FlatList<Album>>,
  'refreshControl' | 'ListHeaderComponent' | 'contentContainerStyle'
>;

export function AlbumGrid({
  albums,
  onAlbumPress,
  ...listProps
}: {
  albums: Album[];
  onAlbumPress: (album: Album) => void;
} & FlatListExtras) {
  const { width } = useWindowDimensions();
  const columns = gridColumns(width);

  return (
    <FlatList
      data={albums}
      key={columns} // re-mount when column count changes (FlatList requirement)
      numColumns={columns}
      keyExtractor={(album) => album.id}
      renderItem={({ item }) => <AlbumCard album={item} onPress={onAlbumPress} />}
      columnWrapperStyle={styles.row}
      contentContainerStyle={styles.content}
      {...listProps}
    />
  );
}

const styles = StyleSheet.create({
  content: {
    padding: spacing.grid,
    gap: spacing.grid,
  },
  row: {
    gap: spacing.grid,
  },
});
