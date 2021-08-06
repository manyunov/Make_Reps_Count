//
//  ViewController.swift
//  Make Reps Count
//
//  Created by Abhimanyu Das on 7/29/21.
//

import UIKit
import Charts

class ViewController: UIViewController {

    @IBOutlet weak var AppName: UILabel!
    @IBOutlet weak var LineChartBox: LineChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let data = [1, 2, 3, 4, 5, 6, 7, 8, 9]
        graphLineChart(dataArray: data)
        
    }
    
    func graphLineChart(dataArray: [Int]){
        //define LineChartBox frame origin (screen top left) and dimensions
        LineChartBox.frame = CGRect(x: 0, y: 0,
                                    width: self.view.frame.size.width,
                                    height: self.view.frame.size.width*3/4)
        
        //center the LineChartBox horizontally and 240 points away from the origin (up)
        LineChartBox.center.x = self.view.center.x
        LineChartBox.center.y = LineChartBox.frame.height/2 + AppName.frame.maxY + 10
        
        //settings when chart has no data
        LineChartBox.noDataText = "No data available"
        LineChartBox.noDataTextColor = UIColor.black
        
        //Initialilze array that will be eventually displayed on the graph
        var entries = [ChartDataEntry]()
        
        //for every element in given dataset, set the X and Y coordinates in a Chart Data entry and append to the list
        for i in 0..<dataArray.count-1 {
            let value = ChartDataEntry(x: Double(i), y: Double(dataArray[i]))
            entries.append(value)
        }
        
        //use the entries object and a label string to make a LineChartDataSet object
        let dataSet = LineChartDataSet(entries: entries, label: "Line Chart")
        
        //customize the graph color settings
        dataSet.colors = ChartColorTemplates.colorful()
        
        //make object that will be added to the chart and set it to variable in the storyboard
        let data =  LineChartData(dataSet: dataSet)
        LineChartBox.data = data
        
        //add settings for the ChartBox
        LineChartBox.chartDescription?.text = "Live EMG"
        
        //Animations
        LineChartBox.animate(xAxisDuration: 2.0, yAxisDuration: 2.0, easingOption: .linear)
    }
}
