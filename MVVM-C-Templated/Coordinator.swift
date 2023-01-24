//
//  Coordinator.swift
//  MVVM-C-Templated
//
//  Created by Arun Sinthanaisirrpi on 24/1/2023.
//

import Foundation
import UIKit
import Combine

protocol NavigationStep {}
protocol CoordinatorType {}

protocol ViewControllerNavigationBinding {
    var nextNavigationStepPublisher: AnyPublisher<NavigationStep?, Never> { get }
}

protocol CoordinatableScreen {
    var screenID: UUID { get }
    var viewController: UIViewController { get }
}

enum FlowMethod {
    case push(viewController: UIViewController)
    case present(viewController: UIViewController)
}

struct FlowLogicHandlerResult {
    let childCoordinator: CoordinatorType
    let id: UUID
    let flow: FlowMethod
}

final class Coordinator<T: NavigationStep>: CoordinatorType {
    typealias FlowLogicHandler = (T) -> FlowLogicHandlerResult?
    private var subscriptions = Set<AnyCancellable>()
    private var childCoordinators = [UUID: CoordinatorType]()
    private var navigationBindings: ViewControllerNavigationBinding?
    private(set) var navigationController: UINavigationController?
    private var navigationStackCleanupManager: NavigationStackCleanupManager
    private var handleFlowLogic: FlowLogicHandler
    let coordinatableScreen: CoordinatableScreen
    
    deinit {
        print("Co-ordinator deallocation")
    }
    
    init(
        screen: CoordinatableScreen,
        navigationController: UINavigationController? = nil,
        flowLogic: @escaping FlowLogicHandler
    ) {
        self.handleFlowLogic = flowLogic
        self.coordinatableScreen = screen
        self.navigationController = navigationController
        self.navigationBindings = screen.viewController as? ViewControllerNavigationBinding
        self.navigationStackCleanupManager = NavigationStackCleanupManager(navigationController: self.navigationController)
        /// navigation stack clean up
        navigationStackCleanupManager
            .$poppedViewControllerID
            .compactMap { $0 }
            .sink { [unowned self] screenID in
                self.removeChild(withId: screenID)
            }
            .store(in: &subscriptions)
        /// Routing
        navigationBindings?
            .nextNavigationStepPublisher
            .compactMap { $0 as? T }
            .compactMap { $0 }
            .sink{ [unowned self] navigationStep in
                if let resultType = self.handleFlowLogic(navigationStep) {
                    self.addChild(coordinator: resultType.childCoordinator, withID: resultType.id)
                    switch resultType.flow {
                        case .present(let childViewController):
                            self.coordinatableScreen.viewController.present(childViewController, animated: true)
                        case .push(let childViewController):
                            self.navigationController?.pushViewController(childViewController, animated: true)
                    }
                }
            }
            .store(in: &subscriptions)
    }
    
    func addChild(coordinator: CoordinatorType, withID id: UUID) {
        childCoordinators[id] = coordinator
        print("Child coordinator count (add): \(childCoordinators.count)")
    }
    
    func removeChild(withId id: UUID) {
        childCoordinators.removeValue(forKey: id)
        print("Child coordinator count (remove): \(childCoordinators.count)")
    }
}

//MARK: - Navigation Stack for Routing
final class NavigationStackCleanupManager: NSObject, UINavigationControllerDelegate {
    
    weak var navigationController: UINavigationController?
    @Published
    var poppedViewControllerID: UUID? = nil
    
    init(navigationController: UINavigationController? = nil) {
        self.navigationController = navigationController
        super.init()
        self.navigationController?.delegate = self
    }
    
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        guard
            let fromViewController = navigationController.transitionCoordinator?.viewController(forKey: .from),
            navigationController.viewControllers.contains(fromViewController) == false,
            let poppedCoordinatableScreen = fromViewController as? CoordinatableScreen
        else {
            return
        }
        /// let the co-ordinator perform the clean up
        poppedViewControllerID = poppedCoordinatableScreen.screenID
    }
}


//MARK: - Sample - Home
enum NavigationStepsFromHome: CaseIterable, NavigationStep {
    case chromecast
    case stationList
    case settings
}

enum NoNavigationSteps: NavigationStep {
    
}

//MARK: - Home root coordinator
enum CoordinatorsFactory {
    static func rootHome() -> Coordinator<NavigationStepsFromHome> {
        let rootsHomeScreen = CoordinatableScreensFactory.rootHomeScreen()
        return Coordinator<NavigationStepsFromHome>(
            screen: rootsHomeScreen,
            navigationController: UINavigationController(rootViewController: rootsHomeScreen.viewController)
        ) { navigationStep in
            switch navigationStep {
                case .stationList:
                    let stationListCoordinator = CoordinatorsFactory.stationList()
                    let stationListScreen = CoordinatableScreensFactory.stationListScreen()
                    return FlowLogicHandlerResult(
                        childCoordinator: stationListCoordinator,
                        id: stationListScreen.screenID,
                        flow: FlowMethod.push(viewController: stationListScreen.viewController)
                    )
                case .chromecast:
                    let chromecastCoorodinator = CoordinatorsFactory.chromecast()
                    let chromecastScreen = CoordinatableScreensFactory.chromeCastScreen()
                    return FlowLogicHandlerResult(
                        childCoordinator: chromecastCoorodinator,
                        id: chromecastScreen.screenID,
                        flow: FlowMethod.push(viewController: chromecastScreen.viewController)
                    )
                case .settings:
                    let settingScreenCoordinator = CoordinatorsFactory.settings()
                    let settingsScreen = CoordinatableScreensFactory.settingsScreen()
                    return FlowLogicHandlerResult(
                        childCoordinator: settingScreenCoordinator,
                        id: settingsScreen.screenID,
                        flow: FlowMethod.push(viewController: settingsScreen.viewController)
                    )
            }
        }
    }
    
    static func chromecast() -> Coordinator<NoNavigationSteps> {
        Coordinator<NoNavigationSteps>(
            screen: CoordinatableScreensFactory.chromeCastScreen()
        ) { _ in nil }
    }
    
    static func settings() -> Coordinator<NoNavigationSteps> {
        Coordinator<NoNavigationSteps>(
            screen: CoordinatableScreensFactory.settingsScreen()
        ) { _ in nil }
    }
    
    static func stationList() -> Coordinator<NavigationStepsFromHome> {
        Coordinator<NavigationStepsFromHome>(
            screen: CoordinatableScreensFactory.stationListScreen()
        ) { navigationStep in
            switch navigationStep {
                case .stationList:
                    let stationListCoordinator = CoordinatorsFactory.stationList()
                    let stationListScreen = CoordinatableScreensFactory.stationListScreen()
                    return FlowLogicHandlerResult(
                        childCoordinator: stationListCoordinator,
                        id: stationListScreen.screenID,
                        flow: FlowMethod.push(viewController: stationListScreen.viewController)
                    )
                case .chromecast:
                    let chromecastCoorodinator = CoordinatorsFactory.chromecast()
                    let chromecastScreen = CoordinatableScreensFactory.chromeCastScreen()
                    return FlowLogicHandlerResult(
                        childCoordinator: chromecastCoorodinator,
                        id: chromecastScreen.screenID,
                        flow: FlowMethod.push(viewController: chromecastScreen.viewController)
                    )
                case .settings:
                    let settingScreenCoordinator = CoordinatorsFactory.settings()
                    let settingsScreen = CoordinatableScreensFactory.settingsScreen()
                    return FlowLogicHandlerResult(
                        childCoordinator: settingScreenCoordinator,
                        id: settingsScreen.screenID,
                        flow: FlowMethod.push(viewController: settingsScreen.viewController)
                    )
            }
        }
    }
}

enum CoordinatableScreensFactory {
    static func rootHomeScreen() -> CoordinatableScreen {
        let viewModel = ReusableDemoViewModel(
            name: "Root",
            backgroundColor: .gray
        )
        return ReusableDemoViewController(withViewModel: viewModel)
    }
    
    static func chromeCastScreen() -> CoordinatableScreen {
        let viewModel = ReusableDemoViewModel(
            name: "Chromecast",
            backgroundColor: .red
        )
        return ReusableDemoViewController(withViewModel: viewModel)
    }
    
    static func settingsScreen() -> CoordinatableScreen {
        let viewModel = ReusableDemoViewModel(
            name: "Settings",
            backgroundColor: .green
        )
        return ReusableDemoViewController(withViewModel: viewModel)
    }
    
    static func stationListScreen() -> CoordinatableScreen {
        let viewModel = ReusableDemoViewModel(
            name: "StationList",
            backgroundColor: .blue
        )
        return ReusableDemoViewController(withViewModel: viewModel)
    }
}
