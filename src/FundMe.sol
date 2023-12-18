// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PriceConverter} from "./PriceConverter.sol";

error FundMe_NotOwner();

// Functions Order:
//// constructor
//// receive
//// fallback
//// external
//// public
//// internal
//// private
//// view / pure

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;

    address private immutable i_priceFeed;
    address[] private s_funders;
    address private immutable i_owner;

    mapping(address => uint256) private s_addressToAmountFunded;

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe_NotOwner();
        _;
    }

    constructor(address _priceFeed) {
        i_owner = msg.sender;
        i_priceFeed = _priceFeed;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        require(msg.value.getConversionRate(i_priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        address[] memory funders = s_funders; //! Copy the array to optimize gas and not reading from storage per loop
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);  //! Empty the array
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    /**
     * Getter Functions
     */

    function getVersion() public returns (uint256) {
        (bool ok, bytes memory result) = address(i_priceFeed).call{value: 0}(abi.encodeWithSignature("version()"));
        require(ok);
        uint256 _version = abi.decode(result, (uint256));
        return _version;
    }

    function getAddressToAmountFunded(address fundingAddress) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (address) {
        return i_priceFeed;
    }
}
