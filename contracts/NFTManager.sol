// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./DynamicNFT.sol";

contract NFTManager is ChainlinkClient, Ownable {

    using Strings for string;
    using Chainlink for Chainlink.Request;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    mapping(bytes32 => address) requestToSender;
    mapping(bytes32 => string) requestToChannelId;
    mapping(bytes32 => string) requestToEndpoint;

    event ListenerRequestInitiated(bytes32 indexed _requestId);
    event RequestListenerFulfilled(bytes32 indexed _requestId, uint256 indexed _listeners, address indexed nftAddress);

    constructor(address _oracle, string memory _jobId) {   
        setPublicChainlinkToken();
        oracle = _oracle;
        jobId = stringToBytes32(_jobId);
        fee = 1 * 10 ** 18; // (Varies by network and job)
    }

    function requestChannelListeners(string memory _channelId, string memory _endpoint) public returns (bytes32 requestId)  {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        // Set the URL to perform the GET request on
        //request.add("get", "https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD");
        //request.add("path", "USD");
        //request.addInt("times", 100);
        
        request.add("id", _channelId);
        request.add("endpoint", _endpoint);

        // Sends the request
        requestId = sendChainlinkRequestTo(oracle, request, fee);
        emit ListenerRequestInitiated(requestId);
        requestToSender[requestId] = msg.sender;
        requestToChannelId[requestId] = _channelId;
        requestToEndpoint[requestId] = _endpoint;
    }

    function fulfill(bytes32 _requestId, uint256 _listeners) public recordChainlinkFulfillment(_requestId)
    {
        //totalListeners = _listeners;
        //apidata.push(APIData(_listeners,"Youtube",requestToChannelId[_requestId],requestToEndpoint[_requestId]));
        DynamicNFT nft = new DynamicNFT(100,requestToChannelId[_requestId],requestToEndpoint[_requestId], _listeners);
        emit RequestListenerFulfilled(_requestId, _listeners, address(nft));
    }

    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly { // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }
}