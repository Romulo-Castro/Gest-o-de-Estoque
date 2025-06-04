// src/data/mockDatabase.js

// Simula um banco de dados em memória. Substitua por uma conexão real (SQLite, etc.)
let stockData = [
    { id: 1, name: 'Caneta Azul', quantity: 50, category: 'Escritório', imageUrl: null },
    { id: 2, name: 'Caderno 96 Folhas', quantity: 30, category: 'Escritório', imageUrl: null },
    { id: 3, name: 'Mouse Sem Fio', quantity: 15, category: 'Informática', imageUrl: null },
    { id: 4, name: 'Teclado USB', quantity: 10, category: 'Informática', imageUrl: null },
  ];
  
  const getStock = () => {
      return [...stockData]; // Retorna uma cópia para evitar mutação direta
  };
  
  const findStockItemById = (id) => {
      return stockData.find(item => item.id === id);
  };
  
  const updateStockItemImage = (id, imageFilename) => {
      const itemIndex = stockData.findIndex(item => item.id === id);
      if (itemIndex !== -1) {
          stockData[itemIndex].imageUrl = imageFilename;
          return stockData[itemIndex]; // Retorna o item atualizado
      }
      return null; // Item não encontrado
  };
  
  // Adicione funções para create, update, delete quando implementar CRUD completo
  // const addStockItem = (item) => { ... };
  // const updateStockItem = (id, data) => { ... };
  // const deleteStockItem = (id) => { ... };
  
  module.exports = {
      getStock,
      findStockItemById,
      updateStockItemImage,
      // Exportar outras funções CRUD aqui
  };