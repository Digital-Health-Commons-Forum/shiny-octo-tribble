using System;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace WorkerTemplateCS
{
    class Program
    {
        private static readonly HttpClient client = new HttpClient();
        private static readonly string apiUrl = "http://127.0.0.1:3000/";

        private static WorkerInfo workerInfo = new WorkerInfo
        {
            Name = "worker-template-cs",
            Description = "This is a template worker written in C#.",
            Author = "PGW"
        };

        private static WorkerState workerState = new WorkerState
        {
            Status = "running",
            Progress = 0,
            Message = "Worker is running...",
            Data = new WorkerData { Stage = 1 }
        };

        static async Task Main(string[] args)
        {
            await InteractWithOpenApi();
            await AdditionalOperation();
        }

        private static async Task InteractWithOpenApi()
        {
            if (workerState.Data.Stage == 1)
            {
                Console.WriteLine("Stage(1): Sending worker info to OpenAPI server...");
                var payload = JsonSerializer.Serialize(workerInfo);
                var content = new StringContent(payload, Encoding.UTF8, "application/json");

                var response = await client.PostAsync(apiUrl + "worker", content);

                if (response.IsSuccessStatusCode)
                {
                    var responseData = await response.Content.ReadAsStringAsync();
                    var data = JsonSerializer.Deserialize<WorkerData>(responseData);
                    Console.WriteLine("Received data from OpenAPI server: " + responseData);
                    workerState.Data.Stage = 2;
                }
                else
                {
                    throw new Exception("Failed to connect to OpenAPI server: " + response.ReasonPhrase);
                }
            }
            else
            {
                var response = await client.GetAsync(apiUrl);

                if (response.IsSuccessStatusCode)
                {
                    var responseData = await response.Content.ReadAsStringAsync();
                    var data = JsonSerializer.Deserialize<WorkerData>(responseData);
                    Console.WriteLine("Received data from OpenAPI server: " + responseData);
                }
                else
                {
                    throw new Exception("Failed to connect to OpenAPI server: " + response.ReasonPhrase);
                }
            }
        }

        private static async Task AdditionalOperation()
        {
            Console.WriteLine("Performing additional operation...");
            // Add your additional operation code here
            await Task.CompletedTask;
        }
    }

    public class WorkerInfo
    {
        public string Name { get; set; }
        public string Description { get; set; }
        public string Author { get; set; }
    }

    public class WorkerState
    {
        public string Status { get; set; }
        public int Progress { get; set; }
        public string Message { get; set; }
        public WorkerData Data { get; set; }
    }

    public class WorkerData
    {
        public int Stage { get; set; }
    }
}