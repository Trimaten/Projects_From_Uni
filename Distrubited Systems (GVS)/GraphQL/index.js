import { ApolloServer } from '@apollo/server';
import { startStandaloneServer } from '@apollo/server/standalone';
import { readFileSync, writeFileSync } from 'fs';

// Load the GraphQL schema
const typeDefs = readFileSync('./schema.graphql', 'utf-8');

// Utility function to load data from the JSON file
function loadData() {
  return JSON.parse(readFileSync('./data.json', 'utf-8'));
}

// Utility function to save data back to the JSON file
function saveData(data) {
  writeFileSync('./data.json', JSON.stringify(data, null, 2));
}

// Resolvers for queries and mutations
const resolvers = {
  Query: {
    getPlaylist: (_, { id }) => {
      const data = loadData();
      return data.playlists.find(playlist => playlist.id === id);
    },
    getAllPlaylists: () => {
      const data = loadData();
      return data.playlists;
    },
    getArtistOfTrack: (_, { songId }) => {
      const data = loadData();
      const song = data.songs.find(song => song.id === songId);
      return song ? song.artist : null;
    },
    getAllSongs: () => {
      const data = loadData();
      return data.songs;
    }
  },
  Mutation: {
    createPlaylist: (_, { name }) => {
      const data = loadData();
      const newPlaylist = {
        id: `${data.playlists.length + 1}`,
        name,
        songs: [],
        length: 0,
        favorite: false,
      };
      data.playlists.push(newPlaylist);
      saveData(data);
      return newPlaylist;
    },
    addSongToPlaylist: (_, { playlistId, songId }) => {
      const data = loadData();
      const playlist = data.playlists.find(pl => pl.id === playlistId);
      const song = data.songs.find(s => s.id === songId);
      if (playlist && song) {
        playlist.songs.push(song);
        playlist.length += song.duration;
        saveData(data);
        return playlist;
      }
      return null;
    },
    setSongFavorite: (_, { songId, favorite }) => {
      const data = loadData();
      const song = data.songs.find(s => s.id === songId);
      if (song) {
        song.favorite = favorite;
        saveData(data);
        return song;
      }
      return null;
    },
    uploadSong: (_, { title, artist, duration }) => {
      const data = loadData();
      const newSong = {
        id: `${data.songs.length + 1}`,
        title,
        artist,
        duration,
        favorite: false,
      };
      data.songs.push(newSong);
      saveData(data);
      return newSong;
    },
    stopServer: () => {
      setTimeout(() => process.exit(0), 1000);
      return "Server will shut down shortly.";
    },
  },
};

// Create the Apollo server
const server = new ApolloServer({ typeDefs, resolvers });

// Start the server
const { url } = await startStandaloneServer(server, {
  listen: { port: 8000 },
});

console.log(`🚀 Server ready at: ${url}`);
