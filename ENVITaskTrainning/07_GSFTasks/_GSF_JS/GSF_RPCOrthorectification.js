// Submit the job
var axios = require("axios");

function reqJson1() {
    const options = {
        method: 'POST',
        url: 'http://localhost:9191/jobs',
        headers: {'content-type': 'application/json'},
        data: {
          "serviceName": 'ENVI',
          "taskName": 'GSF_RPCOrthorectification',
          "inputParameters": {
          		'input_file': 'C:\\Works\\2022ENVI培训班素材包\\ENVI练习数据\\101-处理专题：高分一号二号PMS数据处理\\01-高分一号PMS数据\\GF1_PMS2_E104.0_N36.0_20140724_L1A0000284766\\GF1_PMS2_E104.0_N36.0_20140724_L1A0000284766-MSS2.xml',
          		'sensor_type': 'GF1-PMS'
          }
        }
    };

    axios.request(options).then(function (response) {
        console.log(response.data);
    }).catch(function (error) {
        console.error(error);
    });
}

(() => {
    reqJson1()
})();


