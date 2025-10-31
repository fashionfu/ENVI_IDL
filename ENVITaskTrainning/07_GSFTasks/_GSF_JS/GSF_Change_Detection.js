var axios = require("axios");

function reqJson1() {
    const options = {
        method: 'POST',
        url: 'http://localhost:9191/jobs',
        headers: {'content-type': 'application/json'},
        data: {
          "serviceName": 'ENVI',
          "taskName": 'GSF_Change_Detection',
          "inputParameters": {
				input_file1 : 'C:\\Works\\ENVITaskTrainning\\02_ENVITasks\\data\\july_00_quac.img',
				input_file2 : 'C:\\Works\\ENVITaskTrainning\\02_ENVITasks\\data\\july_06_quac.img',
				detect_method : 'FeatureDifference',
				feature_index : 'NDVI',
				smooth_size : 3,
				aggregate_size : 100,
				export_vector : 1
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