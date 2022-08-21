// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// Se Utiliza Owner para definr dueño del contrato y quien puede añadir nuevas casas o cambiar de Admin
// Queda la variable Owner como el Admin del contrato
import "./Owner.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract BlockCommunity is Owner {

    struct PropertyList {
        address propertyAddress;
        uint fee;
        uint[] pays;
    }

    PropertyList[] properties;

    constructor() {
    }

    modifier requireProperty(address Property) {
        bool encontrado = false;
        uint indice = 0;

        while(properties.length > 0 && !encontrado && indice < properties.length) {
            if (properties[indice].propertyAddress == Property) {
                encontrado = true;
            }
            indice++;
        }

        require(encontrado, "Su propiedad no esta dada de alta");
        _;
    }


    function addProperty (address newProperty, uint fee) public isOwner {
        require(fee > 0, "el Fee debe ser mayor a 0");

        bool encontrado = false;
        uint indice = 0;

        while(properties.length > 0 && !encontrado && indice < properties.length) {
            if (properties[indice].propertyAddress == newProperty) {
                encontrado = true;
                indice = properties.length;
            }

            indice++;
        }

        if(!encontrado) {
            PropertyList memory _propTemp;
            _propTemp.propertyAddress = newProperty;
            _propTemp.fee = fee;
            properties.push(_propTemp);

        }
    }

    function verFees (address Property) public view requireProperty(Property) returns(uint) {
        uint indice = 0;
        uint fee = 0;

        while(properties.length > 0 && indice < properties.length) {
            if (properties[indice].propertyAddress == Property) {
                fee = properties[indice].fee;
                indice = properties.length;
            }

            indice++;
        }
        return fee;
    }

    function feePayment () public requireProperty(msg.sender) {
        uint indice = 0;
        bool find = true;

        while(properties.length > 0  && !find && indice < properties.length) {
            if (properties[indice].propertyAddress == msg.sender) {
                Pay(properties[indice].fee);
                properties[indice].pays.push(checkMonthToPay(msg.sender));
                find == true;
            }
            indice++;
        }
    }

    receive() external payable {}

    function Pay(uint _monto) public payable {
        (bool sent, bytes memory data) = msg.sender.call{value: _monto}("");
        require(sent, "No se pudo transferir el monto");
    }

    function checkMonthToPay(address _property) private view returns (uint) {
        uint indice = 0;
        uint lastmonth = 0;
        uint[] memory _Pays;
        uint lenghtPays;
        while(properties.length > 0 && indice < properties.length) {
            if (properties[indice].propertyAddress == _property) {
                _Pays = properties[indice].pays;
                lenghtPays = _Pays.length;
                if (lenghtPays!=0) {
                    lastmonth = properties[indice].pays[lenghtPays-1];
                }
                indice = properties.length;
            }

            indice++;
        }
        if (lastmonth!=0)
            return nextmonth(lastmonth);
        else
            return 12023;
    }

    // devulve el proximo mes a pagar en base al ultimo pagado
    function nextmonth (uint lastMonth) private pure returns(uint) {
        string memory _last = Strings.toString(lastMonth);
        uint _month;
        uint _year;
        if (lastMonth<102000) {
            _month = st2num(getSlice(0, 0, _last));
            _year = st2num(getSlice(1, 4, _last));
        }
        else {
            _month = st2num(getSlice(0, 1, _last));
            _year = st2num(getSlice(2, 5, _last));
        }
        if (_month != 12)
        {
            _month++;
        } 
        else {
            _month = 1;
            _year +=1;
        }

        return (_month*10000)+_year;
    }

    //regresa un pedazo del string
    function getSlice(uint256 begin, uint256 end, string memory text) private pure returns (string memory) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i=0;i<=end-begin;i++){
            a[i] = bytes(text)[i+begin-1];
        }
        return string(a);    
    }

    function st2num(string memory numString) private pure returns(uint) {
        uint  val=0;
        bytes   memory stringBytes = bytes(numString);
        for (uint  i =  0; i<stringBytes.length; i++) {
            uint exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
           uint jval = uval - uint(0x30);
   
           val +=  (uint(jval) * (10**(exp-1))); 
        } 
      return val;
    }
}