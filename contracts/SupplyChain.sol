// Implement the smart contract SupplyChain following the provided instructions.
// Look at the tests in SupplyChain.test.js and run 'truffle test' to be sure that your contract is working properly.
// Only this file (SupplyChain.sol) should be modified, otherwise your assignment submission may be disqualified.

pragma solidity ^0.5.0;

contract SupplyChain {

  address payable owner;

  constructor() public {
    owner = msg.sender;
  }

  // Create a variable named 'itemIdCount' to store the number of items and also be used as reference for the next itemId.
  uint itemIdCount = 0;
  // Create an enumerated type variable named 'State' to list the possible states of an item (in this order): 'ForSale', 'Sold', 'Shipped' and 'Received'.
  enum State { ForSale, Sold, Shipped, Received }
  // Create a struct named 'Item' containing the following members (in this order): 'name', 'price', 'state', 'seller' and 'buyer'.
  struct Item {
    string name;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }
  // Create a variable named 'items' to map itemIds to Items.
  mapping(uint => Item) items;
  // Create an event to log all state changes for each item.
  event changeItemState(
    uint indexed id,
    string name,
    State state
  );


  // Create a modifier named 'onlyOwner' where only the contract owner can proceed with the execution.
  modifier onlyOwner() {
    require(msg.sender == owner, "onlyOwner Error");
    _;
  }
  // Create a modifier named 'checkState' where the execution can only proceed if the respective Item of a given itemId is in a specific state.
  modifier checkState(uint _itemId, State _state) {
    require(items[_itemId].state == _state, "checkState Error");
    _;
  }
  // Create a modifier named 'checkCaller' where only the buyer or the seller (depends on the function) of an Item can proceed with the execution.
  modifier checkCaller(address _caller) {
    require(msg.sender == _caller, "checkCaller Error");
    _;
  }
  // Create a modifier named 'checkValue' where the execution can only proceed if the caller sent enough Ether to pay for a specific Item or fee.
  modifier checkValue(uint _value) {
    require(msg.value >= _value, "checkValue Error");
    _;
  }


  // Create a function named 'addItem' that allows anyone to add a new Item by paying a fee of 1 finney. Any overpayment amount should be returned to the caller. All struct members should be mandatory except the buyer.
  function addItem(string memory _itemName, uint _price) public payable checkValue(1 finney) {
    Item memory newItem;
    newItem.name = _itemName;
    newItem.price = _price;
    newItem.state = State.ForSale;
    newItem.seller = msg.sender;
    newItem.buyer = address(0);
  
    uint id = itemIdCount;
    items[id] = newItem;
    itemIdCount++;

    uint overpayment = msg.value - (1 finney);
    if (overpayment > 0){
      msg.sender.transfer(overpayment);
    }

    emit changeItemState(id, newItem.name, newItem.state);
  }
  // Create a function named 'buyItem' that allows anyone to buy a specific Item by paying its price. The price amount should be transferred to the seller and any overpayment amount should be returned to the buyer.
  function buyItem(uint _itemId) public checkState(_itemId, State.ForSale) checkValue(items[_itemId].price) payable {
    uint price_amount = items[_itemId].price;

    items[_itemId].state = State.Sold;
    items[_itemId].buyer = msg.sender;
    items[_itemId].seller.transfer(price_amount);

    uint overpayment = msg.value - items[_itemId].price;
    if (overpayment > 0){
      msg.sender.transfer(overpayment);
    }
    
    emit changeItemState(_itemId, items[_itemId].name, items[_itemId].state);
  }

  // Create a function named 'shipItem' that allows the seller of a specific Item to record that it has been shipped.
  function shipItem(uint _itemId) public checkState(_itemId, State.Sold) checkCaller(items[_itemId].seller) {
    items[_itemId].state = State.Shipped;

    emit changeItemState(_itemId, items[_itemId].name, items[_itemId].state);
  }
  // Create a function named 'receiveItem' that allows the buyer of a specific Item to record that it has been received.
  function receiveItem(uint _itemId) public checkState(_itemId, State.Shipped) checkCaller(items[_itemId].buyer) {
    items[_itemId].state = State.Received;

    emit changeItemState(_itemId, items[_itemId].name, items[_itemId].state);
  }
  // Create a function named 'getItem' that allows anyone to get all the information of a specific Item in the same order of the struct Item.
  function getItem(uint _itemId) public view returns(string memory, uint, State, address, address) {
    return (items[_itemId].name, items[_itemId].price, items[_itemId].state, items[_itemId].seller, items[_itemId].buyer);
  }
  // Create a function named 'withdrawFunds' that allows the contract owner to withdraw all the available funds.
  function withdrawFunds() public onlyOwner {
    require(address(this).balance > 0, 'No funds available.');
    owner.transfer(address(this).balance);
  }
}
