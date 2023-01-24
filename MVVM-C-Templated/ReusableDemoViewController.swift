//
//  ViewController.swift
//  MVVM-C-Templated
//
//  Created by Arun Sinthanaisirrpi on 24/1/2023.
//

import UIKit

import Foundation
import UIKit
import Combine

struct ReusableDemoViewModel {
    let name: String
    let backgroundColor: UIColor
    let hasTabBar: Bool
    
    init(name: String, backgroundColor: UIColor, hasTabBar: Bool = false) {
        self.name = name
        self.backgroundColor = backgroundColor
        self.hasTabBar = hasTabBar
    }
    
    static let unitinitilzed: ReusableDemoViewModel = {
        ReusableDemoViewModel(
            name: "Unitilzed screen use init(withViewModel) method",
            backgroundColor: .red)
    }()
}

final class RouteActionCell: UITableViewCell {
    static let identifier = "RouteActionCellIdentifier"
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

final class ReusableDemoViewController: UIViewController, CoordinatableScreen, ViewControllerNavigationBinding {
    let viewModel: ReusableDemoViewModel
    let screenID = UUID()
    var viewController: UIViewController { self }
    
    @Published
    private var nextNavigationStep: NavigationStep?
    var nextNavigationStepPublisher: AnyPublisher<NavigationStep?, Never> {
        $nextNavigationStep.eraseToAnyPublisher()
    }
    
    deinit {
        print("deallocating : \(viewModel.name)")
    }
    
    private let infoLabel: UILabel = {
        let result = UILabel(frame: .zero)
        result.translatesAutoresizingMaskIntoConstraints = false
        return result
    }()
    
    private let tableViewForMockingActions: UITableView = {
        let result = UITableView(frame: .zero)
        result.translatesAutoresizingMaskIntoConstraints = false
        result.register(UITableViewCell.self, forCellReuseIdentifier: RouteActionCell.identifier)
        return result
    }()
    
    let destinationRoutes: [NavigationStepsFromHome]
    
    init(
        withViewModel viewModel: ReusableDemoViewModel,
        destinationRoutes: [NavigationStepsFromHome] = NavigationStepsFromHome.allCases
    ) {
        self.viewModel = viewModel
        self.destinationRoutes = destinationRoutes
        super.init(nibName: nil, bundle: nil)
        if viewModel.hasTabBar {
            self.tabBarItem = UITabBarItem(
                title: viewModel.name,
                image: nil,
                selectedImage: nil
            )
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        viewModel = ReusableDemoViewModel.unitinitilzed
        destinationRoutes = []
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        viewModel = ReusableDemoViewModel.unitinitilzed
        destinationRoutes = []
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(infoLabel)
        let viewSafeAreaLayoutGuide = view.safeAreaLayoutGuide
        let constraints = [
            infoLabel.centerXAnchor.constraint(equalTo: viewSafeAreaLayoutGuide.centerXAnchor),
            infoLabel.leadingAnchor.constraint(equalTo: viewSafeAreaLayoutGuide.leadingAnchor),
            infoLabel.trailingAnchor.constraint(equalTo: viewSafeAreaLayoutGuide.trailingAnchor),
            infoLabel.topAnchor.constraint(equalTo: viewSafeAreaLayoutGuide.topAnchor, constant: 18)
        ]
        NSLayoutConstraint.activate(constraints)
        view.addSubview(tableViewForMockingActions)
        let tableviewConstraints = [
            tableViewForMockingActions.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 18),
            tableViewForMockingActions.leadingAnchor.constraint(equalTo: viewSafeAreaLayoutGuide.leadingAnchor),
            tableViewForMockingActions.trailingAnchor.constraint(equalTo: viewSafeAreaLayoutGuide.trailingAnchor),
            tableViewForMockingActions.bottomAnchor.constraint(equalTo: viewSafeAreaLayoutGuide.bottomAnchor)
        ]
        NSLayoutConstraint.activate(tableviewConstraints)
        view.backgroundColor = viewModel.backgroundColor
        infoLabel.text = viewModel.name
        tableViewForMockingActions.dataSource = self
        tableViewForMockingActions.delegate = self
    }
}

extension ReusableDemoViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RouteActionCell.identifier, for: indexPath)
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        destinationRoutes.count
    }
}

extension ReusableDemoViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /// perform the routing
        nextNavigationStep = destinationRoutes[indexPath.row]
    }
}


